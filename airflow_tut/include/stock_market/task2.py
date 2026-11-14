from pyspark.sql import SparkSession 
from pyspark.sql.functions import col

def drop_column_from_dataset(input_path, output_path):
    spark = SparkSession.builder.appName("DropColumnApp").getOrCreate()

    df = spark.read.csv(input_path, header=True, inferSchema=True)

    df = df.withColumn("PriceAfterDiscount", (col("gross_amount") - col("net_amount")))

    df.write.csv(output_path, header=True) 

    spark.stop()

if __name__ == "__main__":
    input_dataset_path = "airflow_tut/fact_sales.csv"
    output_dataset_path = "airflow_tut/fact_sales_cleaned.csv"

    drop_column_from_dataset(input_dataset_path, output_dataset_path)