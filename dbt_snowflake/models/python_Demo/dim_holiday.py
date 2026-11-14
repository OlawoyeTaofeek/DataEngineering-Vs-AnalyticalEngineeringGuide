import holidays
from snowflake.snowpark.types import StructType, StructField, DateType, BooleanType, StringType


def model(dbt, session):
    dbt.config(materialized="table", packages=["holidays"])

    ng_holidays = holidays.country_holidays("NG")

    rows = dbt.ref("date_spine").select("DATE_DAY").collect()

    data = []
    for r in rows:
        d = r["DATE_DAY"]
        if hasattr(d, "date"):          # timestamp → date, if the spine returns timestamps
            d = d.date()
        data.append((d, d in ng_holidays, ng_holidays.get(d)))

    schema = StructType([
        StructField("DATE_DAY", DateType()),
        StructField("IS_HOLIDAY", BooleanType()),
        StructField("HOLIDAY_NAME", StringType()),
    ])

    return session.create_dataframe(data, schema=schema)