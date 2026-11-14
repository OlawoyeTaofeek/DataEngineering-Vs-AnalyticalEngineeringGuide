from airflow.decorators import dag, task
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

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
def run_spark_submit():
    submit_job = SparkSubmitOperator(
        task_id="submit_job",
        application="include/stock_market/task2.py",
        conn_id="spark_default",
        total_executor_cores="1",
        executor_cores="1",
        executor_memory="2g",
        num_executors="1",
        driver_memory="2g",
        verbose=True
    )
    # load_to_snowflake = SQLExecuteQueryOperator(
    #     task_id="load_to_snowflake",
    #     conn_id="snowflake",               # must match your connection id exactly
    #     sql="""
    #         COPY INTO STOCK.PRICES
    #         FROM @STOCK.PRICES_STAGE/NVDA/
    #         FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"')
    #         PATTERN = '.*[.]csv'
    #         ON_ERROR = ABORT_STATEMENT
    #     """,
    # )


    # submit_job >> load_to_snowflake

run_spark_submit()

