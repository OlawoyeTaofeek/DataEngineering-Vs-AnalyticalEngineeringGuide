FROM bde2020/spark-python-template:3.3.0-hadoop3.3

COPY stock_transform.py /app/

RUN wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.2/hadoop-aws-3.3.2.jar \
    && wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.1026/aws-java-sdk-bundle-1.11.1026.jar \
    && mv hadoop-aws-3.3.2.jar aws-java-sdk-bundle-1.11.1026.jar /spark/jars/

ENV SPARK_MASTER_NAME=spark-master
ENV SPARK_MASTER_PORT=7077
ENV ENDPOINT=http://minio:9000
ENV SPARK_APPLICATION_PYTHON_LOCATION=/app/stock_transform.py
ENV ENABLE_INIT_DAEMON=false

# Run spark-submit directly, so a crash makes the container (and the Airflow task) fail
CMD ["/bin/bash", "-c", "/spark/bin/spark-submit --master spark://${SPARK_MASTER_NAME}:${SPARK_MASTER_PORT} --jars /spark/jars/hadoop-aws-3.3.2.jar,/spark/jars/aws-java-sdk-bundle-1.11.1026.jar ${SPARK_APPLICATION_PYTHON_LOCATION}"]