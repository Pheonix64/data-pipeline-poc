# DEPLOYMENT GUIDE - Data Pipeline POC BCEAO

## Version Information

- **Apache Iceberg**: 1.8.1
- **Apache Spark**: 3.5.5
- **dbt**: 1.9.0
- **MinIO**: Latest
- **Python**: 3.11
- **Hadoop AWS**: 3.3.4
- **AWS SDK Bundle**: 1.12.262

## System Requirements

### Hardware
- **Minimum**: 8GB RAM, 20GB disk space
- **Recommended**: 16GB RAM, 50GB disk space
- **CPU**: 4 cores minimum

### Software
- Docker Desktop 4.0+
- Docker Compose 2.0+
- Git

## Pre-Deployment Checklist

- [ ] Docker Desktop installed and running
- [ ] Ports 4040, 8888, 9000, 9001, 8181, 10000, 5433, 8010 available
- [ ] Downloaded AWS SDK JARs (hadoop-aws-3.3.4.jar, aws-java-sdk-bundle-1.12.262.jar)
- [ ] Created `.env` file with proper credentials
- [ ] Airbyte configured (if using external data ingestion)

## Step-by-Step Deployment

### 1. Clone Repository

```bash
git clone <repository-url>
cd data-pipeline-poc
```

### 2. Setup Environment Variables

Create `.env` file in project root:

```env
# Airbyte configuration
AIRBYTE_VERSION=0.50.44

# MinIO credentials
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=SuperSecret123

# TimescaleDB/Postgres credentials
POSTGRES_DB=monetary_policy_dm
POSTGRES_USER=postgres
POSTGRES_PASSWORD=PostgresPass123
```

### 3. Download AWS SDK JARs

Create `jars/` directory and download required JARs:

```bash
mkdir -p jars
cd jars

# Download hadoop-aws-3.3.4.jar
curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

# Download aws-java-sdk-bundle-1.12.262.jar
curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

cd ..
```

### 4. Build Docker Images

```bash
docker-compose build
```

Expected output:
- Building spark-iceberg image with dbt-spark and custom configuration
- Images should be created successfully

### 5. Start Services

```bash
docker-compose up -d
```

### 6. Verify Services

Wait 30-60 seconds for all services to start, then check:

```bash
docker-compose ps
```

All services should show "Up" or "healthy" status.

### 7. Access Web Interfaces

- MinIO Console: http://localhost:9001 (admin/SuperSecret123)
- Jupyter Notebook: http://localhost:8888
- Spark UI: http://localhost:4040

### 8. Initialize Bronze Layer (Airbyte Integration)

#### 8a. Configure Airbyte

1. Set destination to S3 (MinIO)
2. Configuration:
   - S3 Bucket Name: `lakehouse`
   - S3 Bucket Path: `bronze/indicateurs_economiques_uemoa`
   - S3 Endpoint: `http://minio:9000`
   - Access Key ID: `admin`
   - Secret Access Key: `SuperSecret123`
   - S3 Path Format: `${NAMESPACE}/${STREAM_NAME}/${YEAR}_${MONTH}_${DAY}_${EPOCH}_${UUID}.parquet`
   - Output Format: Parquet (Columnar Storage)
   - Compression: SNAPPY

3. Run Airbyte sync

#### 8b. Create Iceberg Table from Parquet

Copy the table creation script:

```bash
docker cp create_uemoa_table.py spark-iceberg:/tmp/
```

Run the script to create Bronze Iceberg table:

```bash
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py"
```

Expected output:
```
Table bronze.indicateurs_economiques_uemoa created successfully!
```

### 9. Run dbt Transformations

```bash
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"
```

Expected output:
```
Done. PASS=9 WARN=0 ERROR=0 SKIP=0 TOTAL=9
```

All 9 models should pass:
1. dim_uemoa_indicators (Silver)
2. stg_events (Silver)
3. stg_users (Silver)
4. gold_kpi_uemoa_growth_yoy (Gold)
5. gold_mart_uemoa_external_stability (Gold)
6. gold_mart_uemoa_external_trade (Gold)
7. gold_mart_uemoa_monetary_dashboard (Gold)
8. gold_mart_uemoa_public_finance (Gold)
9. fct_events_enriched (Gold)

### 10. Validate Data Quality

```bash
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"
```

## Post-Deployment Verification

### Check Bronze Layer

```bash
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) as row_count FROM bronze.indicateurs_economiques_uemoa;"
```

### Check Silver Layer

```bash
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) as row_count FROM default_silver.dim_uemoa_indicators;"
```

### Check Gold Layer

```bash
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW TABLES IN default_gold;"
```

### Verify MinIO Storage

Access MinIO console at http://localhost:9001 and verify:
- `lakehouse` bucket exists
- `bronze/`, `silver/`, `gold/` directories contain data

## Maintenance

### Daily Operations

```bash
# Check service health
docker-compose ps

# View logs
docker-compose logs -f spark-iceberg

# Restart a service
docker-compose restart spark-iceberg
```

### Data Refresh

```bash
# 1. Run Airbyte sync (if using)
# 2. Recreate Bronze table (if schema changed)
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py"

# 3. Run dbt transformations
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"
```

### Backup

```bash
# Backup MinIO data
docker exec mc mc mirror bceao-data/lakehouse /backup/lakehouse

# Backup dbt project
tar -czf dbt_project_backup.tar.gz dbt_project/
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker resources
docker system df

# Clean up unused resources
docker system prune -a

# Restart Docker Desktop
```

### Spark Jobs Fail

```bash
# Check Spark logs
docker logs spark-iceberg

# Verify JARs are mounted
docker exec spark-iceberg ls -la /opt/spark/extra-jars/

# Test S3 connectivity
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  --conf 'spark.hadoop.fs.s3a.access.key=admin' \
  --conf 'spark.hadoop.fs.s3a.secret.key=SuperSecret123' \
  --conf 'spark.hadoop.fs.s3a.endpoint=http://minio:9000' \
  --conf 'spark.hadoop.fs.s3a.path.style.access=true' \
  --conf 'spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem' \
  --py-files /tmp/test_s3.py"
```

### dbt Models Fail

```bash
# Run with debug mode
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --debug"

# Check specific model
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select dim_uemoa_indicators"

# Verify source table exists
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW TABLES IN bronze;"
```

## Security Considerations

### Production Deployment

For production environments, ensure:

1. **Change default passwords** in `.env`
2. **Use proper network segmentation** (separate networks for each layer)
3. **Enable TLS/SSL** for all communications
4. **Implement proper access controls** on MinIO buckets
5. **Use secrets management** (e.g., HashiCorp Vault, AWS Secrets Manager)
6. **Enable audit logging** on all components
7. **Implement data encryption at rest** on MinIO
8. **Restrict Jupyter Notebook access** with authentication

### Network Security

```yaml
# Example: Restrict service exposure in docker-compose.yml
services:
  spark-iceberg:
    ports:
      - "127.0.0.1:8888:8888"  # Only localhost can access
      - "127.0.0.1:4040:4040"
```

## Performance Tuning

### Spark Configuration

Edit `spark-defaults.conf` for production workloads:

```properties
# Memory settings
spark.driver.memory=4g
spark.executor.memory=8g

# Parallelism
spark.sql.shuffle.partitions=200
spark.default.parallelism=100

# S3A optimization
spark.hadoop.fs.s3a.connection.maximum=200
spark.hadoop.fs.s3a.threads.max=64
spark.hadoop.fs.s3a.fast.upload=true
```

### MinIO Optimization

```bash
# Increase MinIO memory allocation in docker-compose.yml
environment:
  - MINIO_SERVER_URL=http://minio:9000
  - MINIO_BROWSER_REDIRECT_URL=http://localhost:9001
```

## Monitoring

### Key Metrics to Monitor

1. **Spark Jobs**:
   - Job duration
   - Failed tasks
   - Memory usage

2. **MinIO**:
   - Storage usage
   - API request latency
   - Bucket size

3. **dbt**:
   - Model run time
   - Test failures
   - Lineage coverage

### Logging

```bash
# Aggregate logs from all services
docker-compose logs > pipeline_logs.txt

# Monitor in real-time
docker-compose logs -f --tail=100
```

## Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Review troubleshooting section
3. Verify all prerequisites are met
4. Contact technical support with logs and error messages
