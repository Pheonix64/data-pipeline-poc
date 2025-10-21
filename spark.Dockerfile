# Extend the official Spark-Iceberg image
FROM tabulario/spark-iceberg:latest

# Install dbt-spark with PyHive dependencies
RUN pip install --no-cache-dir dbt-spark[PyHive]==1.9.3

# Copy initialization scripts
COPY init-scripts/ /opt/spark/init-scripts/

# Copy dbt project
COPY dbt_project/ /opt/spark/app/

# Set working directory
WORKDIR /opt/spark/app

# The entrypoint is inherited from the base image
