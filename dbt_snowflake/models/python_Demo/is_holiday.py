import holidays
import pandas

def model(dbt, session):
    dbt.config(
        materialized="table",
        packages=["pandas", "pyarrow", "holidays"],
    )

    country = dbt.config.meta_get("holiday_country") or "US"
    country_holidays = holidays.country_holidays(country)

    df = dbt.ref("date_spine").to_pandas()

    df["IS_HOLIDAY"] = df["DATE_DAY"].apply(lambda d: d in country_holidays)
    df["HOLIDAY_NAME"] = df["DATE_DAY"].apply(lambda d: country_holidays.get(d))

    return df