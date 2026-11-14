from snowflake.snowpark.functions import col, sum as sum_

def model(dbt, session):
    dbt.config(materialized="table")

    df = (
        dbt.ref("fct_orders")
           .group_by("CUSTOMER_ID")
           .agg(sum_(col("AMOUNT")).alias("TOTAL"))
    )

    return df