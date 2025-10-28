from pyspark.sql import SparkSession

# Create Spark session with explicit S3 configuration
spark = SparkSession.builder \
    .appName("CreateUemoaTable") \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "SuperSecret123") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Read Parquet files from MinIO
df = spark.read.parquet("s3a://lakehouse/bronze/indicateurs_economiques_uemoa/")

# Write as Iceberg table
df.writeTo("bronze.indicateurs_economiques_uemoa") \
    .using("iceberg") \
    .createOrReplace()

print("Table bronze.indicateurs_economiques_uemoa created successfully!")

# Show table info
spark.sql("DESCRIBE EXTENDED bronze.indicateurs_economiques_uemoa").show(truncate=False)

# Stop session
spark.stop()
