from snowflake.core import Root, CreateMode
from snowflake.core.database import Database
from snowflake.core.table import Table, TableColumn
from snowflake.snowpark.types import StructType, StructField, IntegerType, StringType
import os
from snowflake.snowpark import Session
from dotenv import load_dotenv

load_dotenv(override=True)

params = {
    "account": os.environ["SNOWFLAKE_ACCOUNT"],
    "user": os.environ["SNOWFLAKE_USER"],
    "private_key_file": os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"],
    "authenticator": "SNOWFLAKE_JWT",
    "role": os.environ["SNOWFLAKE_ROLE"],
    "warehouse": os.environ["SNOWFLAKE_WAREHOUSE"],
    "database": os.environ["SNOWFLAKE_DATABASE"],
    "schema": os.environ["SNOWFLAKE_SCHEMA"],
}


session = Session.builder.configs(params).create()