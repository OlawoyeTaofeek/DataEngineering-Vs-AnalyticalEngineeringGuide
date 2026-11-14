from airflow.hooks.base import BaseHook
import requests
from airflow.exceptions import AirflowNotFoundException
from airflow.providers.postgres.hooks.postgres import PostgresHook
from sqlalchemy import Column, Integer, String, DateTime
import json
from minio import Minio
from io import BytesIO

BUCKET = "stock-market"

def _get_minio_client():
    minio = BaseHook.get_connection(conn_id="minio")
    client = Minio(
        endpoint=minio.extra_dejson['endpoint_url'].split("//")[1],
        access_key=minio.login,
        secret_key=minio.password,
        secure=False,
    )
    return client   

def _get_stock_prices(url: str, symbol: str):
    url = f"{url}{symbol}?metrics=high&interval=1d&range=2y"
    api = BaseHook.get_connection(conn_id="stock_api")
    response = requests.get(url, headers=api.extra_dejson['headers'])
    return json.dumps(response.json()['chart']['result'][0])

def _store_prices(stock):
    client = _get_minio_client()
    if not client.bucket_exists(BUCKET):
        client.make_bucket(BUCKET)

    stock = json.loads(stock)
    symbol = stock['meta']['symbol']
    data = json.dumps(stock, ensure_ascii=False).encode("utf-8")
    objw = client.put_object(
        bucket_name=BUCKET,
        object_name = f'{symbol}/prices.json',
        data = BytesIO(data),
        length=len(data)
    )
    return f"{objw.bucket_name}/{symbol}"


def _get_formatted_csv(path: str) -> str:
    client = _get_minio_client()
    bucket, folder = path.split("/", 1)                   # "stock-market", "NVDA"
    prefix = f"{folder}/formatted_prices_csv/"            # your Spark script writes CSV here
    for obj in client.list_objects(bucket, prefix=prefix, recursive=True):
        if obj.object_name.endswith(".csv"):
            return obj.object_name                        # e.g. "NVDA/formatted_prices_csv/part-00000-....csv"
    raise AirflowNotFoundException(f"No CSV found unde r {bucket}/{prefix}")


def _load_to_postgres(object_name: str, path: str) -> int:
    bucket, symbol = path.split("/", 1)
    data = _get_minio_client().get_object(bucket, object_name)
    conn = PostgresHook(postgres_conn_id="postgres").get_conn()      # psycopg2 starts a transaction automatically
    try:
        with conn.cursor() as cur:
            cur.execute("CREATE SCHEMA IF NOT EXISTS stock")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS stock.prices (
                    symbol     TEXT,
                    timestamp  BIGINT,
                    close      DOUBLE PRECISION,
                    high       DOUBLE PRECISION,
                    low        DOUBLE PRECISION,
                    open       DOUBLE PRECISION,
                    volume     BIGINT,
                    date       DATE,
                    PRIMARY KEY (symbol, date)
                )
            """)

            cur.execute("CREATE TABLE IF NOT EXISTS stock.prices_stage (LIKE stock.prices INCLUDING DEFAULTS)")
            cur.execute("TRUNCATE stock.prices_stage")
            cur.copy_expert("COPY stock.prices_stage FROM STDIN WITH (FORMAT csv, HEADER true)", data)

            # validate before touching the real table
            cur.execute("SELECT count(*), count(DISTINCT date) FROM stock.prices_stage")
            rows, days = cur.fetchone()
            if rows == 0 or rows != days:
                raise ValueError(f"Bad file: {rows} rows, {days} distinct days")

            cur.execute("""
                INSERT INTO stock.prices SELECT * FROM stock.prices_stage
                ON CONFLICT (symbol, date) DO UPDATE
                   SET close = EXCLUDED.close, high = EXCLUDED.high, low = EXCLUDED.low,
                       open = EXCLUDED.open, volume = EXCLUDED.volume
            """)
        conn.commit()                       # = COMMIT
        return rows
    except Exception:
        conn.rollback()                     # = ROLLBACK: the real table is untouched
        raise
    finally:
        data.close(); data.release_conn(); conn.close()

