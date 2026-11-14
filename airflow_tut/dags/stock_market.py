from airflow.decorators import dag, task
from datetime import datetime, timedelta
from airflow.sensors.base import PokeReturnValue
from airflow.hooks.base import BaseHook
import requests
from include.stock_market.tasks import _get_stock_prices, _store_prices, _get_formatted_csv, _load_to_postgres
from airflow.operators.python import PythonOperator
from airflow.providers.docker.operators.docker import DockerOperator
from astro import sql as aql
from astro.files import File
from astro.sql.table import Table, Metadata
BUCKET = 'stock-market'
SYMBOL = 'NVDA'

@dag(
    start_date=datetime(2025, 1, 1),
    schedule="@daily",
    catchup=False,
    max_active_runs=1,
    tags=['stock_market'],
    default_args={
        "owner": "Taofeek",
        "retries": 3,
        "retry_delay": timedelta(minutes=5),
        "depends_on_past": False,
    },
)
def stock_market():
    
    @task.sensor(poke_interval=30, timeout=300, mode="poke")
    def is_api_available() -> PokeReturnValue:
        api = BaseHook.get_connection("stock_api")
        url = f"{api.host}{api.extra_dejson['endpoint']}"
        response = requests.get(f"{url}{SYMBOL}", headers=api.extra_dejson["headers"], timeout=10)
        print(f"URL: {url}{SYMBOL}  Status: {response.status_code}")
        condition = response.status_code == 200
        return PokeReturnValue(is_done=condition, xcom_value=url)

    get_stock_prices = PythonOperator(
        task_id = "get_stock_prices",
        python_callable=_get_stock_prices,
        op_kwargs= {"url": '{{ ti.xcom_pull(task_ids="is_api_available") }}', 'symbol': SYMBOL}
    )

    store_prices = PythonOperator(
        task_id="store_prices",
        python_callable=_store_prices,
        op_kwargs={"stock": '{{ ti.xcom_pull(task_ids="get_stock_prices") }}'}
    )

    format_prices = DockerOperator(
        task_id="format_prices",
        image="airflow/stock-app",
        container_name="format_prices_new",
        api_version="auto",
        auto_remove="success",
        docker_url="tcp://docker-proxy:2375",
        network_mode="container:spark-master",
        tty=True,
        xcom_all=False,
        mount_tmp_dir=False,
        environment={
            "SPARK_APPLICATION_ARGS": '{{ ti.xcom_pull(task_ids="store_prices") }}',
        },
    )

    get_formatted_csv = PythonOperator(
        task_id = "get_formatted_csv",
        python_callable= _get_formatted_csv,
        op_kwargs= {
            "path": '{{ ti.xcom_pull(task_ids="store_prices") }}'
        }
    )

    load_to_postgres = PythonOperator(
        task_id="load_to_postgres",
        python_callable=_load_to_postgres,
        op_kwargs={
            "object_name": '{{ ti.xcom_pull(task_ids="get_formatted_csv") }}',   # e.g. NVDA/formatted_prices_csv/part-00000-....csv
            "path": '{{ ti.xcom_pull(task_ids="store_prices") }}',               # e.g. stock-market/NVDA
        },
    )

    is_api_available() >> get_stock_prices >> store_prices >> format_prices >> get_formatted_csv >> load_to_postgres

    load_to_wh = aql.load_file(
        task_id = 'load_to_wh',
        input_file=File(
            path=f"s3://{BUCKET}/{{{{ ti.xcom_pull(task_ids='get_formatted_csv') }}}}",
            conn_id="minio"
        ),
        output_table=Table(
            name="stock_market",
            conn_id='pistgres',
            metadata=Metadata(
                schema='public'
            )
        ),
        load_options={
            "aws_access_key_id": BaseHook.get_connection('minio').login,
            "aws_secret_access_key": BaseHook.get_connection('minio').password,
            "endpoint_url": BaseHook.get_connection('minio').host
        }
    )

    is_api_available() >> get_stock_prices >> store_prices >> format_prices >> get_formatted_csv >> load_to_postgres
    load_to_wh


stock_market()