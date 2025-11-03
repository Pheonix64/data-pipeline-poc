# Data Pipeline POC - BCEAO

[![Apache Iceberg](https://img.shields.io/badge/Apache%20Iceberg-1.8-blue.svg)](https://iceberg.apache.org/)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-3.5-orange.svg)](https://spark.apache.org/)
[![dbt](https://img.shields.io/badge/dbt-1.9-red.svg)](https://www.getdbt.com/)
[![MinIO](https://img.shields.io/badge/MinIO-S3%20Compatible-red.svg)](https://min.io/)
[![Airbyte](https://img.shields.io/badge/Airbyte-Integrated-purple.svg)](https://airbyte.com/)

A modern **Data Lakehouse** implementation using the **Medallion Architecture** (Bronze, Silver, Gold) with Apache Iceberg, Spark, dbt, and Airbyte for UEMOA economic indicators.

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[README.md](./README.md)** (this file) | Vue d'ensemble du projet, architecture et setup rapide |
| **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** ⚡ | Guide de référence rapide - Commandes essentielles |
| **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** 🚀 | Guide de déploiement complet étape par étape |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** 🏗️ | Documentation technique approfondie |
| **[CONTRIBUTING.md](./CONTRIBUTING.md)** 🤝 | Guide de contribution pour développeurs |
| **[CHANGELOG.md](./CHANGELOG.md)** 📝 | Historique des versions et modifications |
| **[QUICKSTART_FR.md](./QUICKSTART_FR.md)** 🇫🇷 | Démarrage rapide en français |
| **[TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)** | Guide des transformations dbt |
| **[AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md)** | Configuration Airbyte → MinIO |
| **[MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md)** | Structure des buckets MinIO |

[🇫🇷 Version Française](./README_FR.md) | [⚡ Quick Start](./QUICKSTART_FR.md)

## 🏗️ Architecture Overview

This project implements a complete data pipeline for UEMOA (West African Economic and Monetary Union) economic indicators with:

- **Data Ingestion**: Airbyte (extracting data from sources)
- **Storage Layer**: MinIO (S3-compatible object storage)
- **Table Format**: Apache Iceberg (ACID transactions, time travel, schema evolution)
- **Processing Engine**: Apache Spark 3.5 with Iceberg support
- **Transformation Orchestration**: dbt 1.9 (Data Build Tool)
- **Serving Layers**: TimescaleDB (time-series), ChromaDB (vector database)

### Medallion Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                            │
│                      (Airbyte)                                │
│          Extracting UEMOA Economic Indicators                 │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼ (Parquet files with Snappy compression)
┌──────────────────────────────────────────────────────────────┐
│                    BRONZE LAYER                               │
│     (Raw Data - indicateurs_economiques_uemoa)                │
│                   Storage: MinIO (S3)                         │
│      Format: Iceberg tables from Parquet files                │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │  Transformation (dbt / Spark)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    SILVER LAYER                               │
│         (Cleaned Data - dim_uemoa_indicators)                 │
│     Cleaning, Validation, Type Casting, Calculations          │
│                   Format: Apache Iceberg                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │  Aggregation & Business Logic
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    GOLD LAYER                                 │
│           (Analytics-Ready Data Marts)                        │
│  • gold_kpi_uemoa_growth_yoy                                  │
│  • gold_mart_uemoa_external_stability                         │
│  • gold_mart_uemoa_external_trade                             │
│  • gold_mart_uemoa_monetary_dashboard                         │
│  • gold_mart_uemoa_public_finance                             │
│                   Format: Apache Iceberg                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                 CONSUMPTION LAYERS                            │
│    • TimescaleDB (Time Series Analytics)                     │
│    • ChromaDB (Vector Search for AI/ML)                      │
│    • Jupyter Notebooks (Ad-hoc Analysis)                     │
│    • BI Dashboards (Tableau, Power BI, etc.)                 │
└──────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (with at least 8GB RAM)
- Docker Compose
- Available ports: 4040, 8888, 9000, 9001, 8181, 10000, 5433, 8010

### 1. Create `.env` file

```env
# Airbyte configuration
AIRBYTE_VERSION=0.50.44

# MinIO credentials (used by MinIO, Spark, and mc)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=SuperSecret123

# TimescaleDB/Postgres credentials
POSTGRES_DB=monetary_policy_dm
POSTGRES_USER=postgres
POSTGRES_PASSWORD=PostgresPass123
```

### 2. Prepare AWS SDK JARs

Download the following JARs and place them in the `jars/` directory:

```bash
# Create jars directory
mkdir jars

# Download required JARs
# 1. hadoop-aws-3.3.4.jar
# Download from: https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

# 2. aws-java-sdk-bundle-1.12.262.jar
# Download from: https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

### 3. Start the services

```bash
# Build images (first time only)
docker-compose build

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 4. Verify installation

- **MinIO Console**: http://localhost:9001 (Login: admin / SuperSecret123)
- **Jupyter Notebook**: http://localhost:8888 (No password required)
- **Spark UI**: http://localhost:4040
- **Iceberg REST Catalog**: http://localhost:8181

### 5. Initialize Bronze layer (if using Airbyte)

If you're using Airbyte to ingest UEMOA economic indicators:

1. Configure Airbyte to output Parquet files with Snappy compression to `s3a://lakehouse/bronze/indicateurs_economiques_uemoa/`
2. After Airbyte sync, create the Iceberg table from Parquet files:

```bash
# Copy the creation script to the container
docker cp create_uemoa_table.py spark-iceberg:/tmp/

# Run the script to create the Bronze Iceberg table
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py"
```

### 6. Run dbt transformations

```bash
# Execute all transformations (Bronze → Silver → Gold)
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"

# Run tests to validate data quality
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"
```

## 📊 Components

| Service | Port | Description |
|---------|------|-------------|
| **MinIO** | 9000, 9001 | S3-compatible object storage |
| **Iceberg REST** | 8181 | Iceberg catalog service |
| **Spark/Jupyter** | 8888, 4040, 10000 | Processing engine & notebooks |
| **dbt** | - | Transformation orchestration |
| **TimescaleDB** | 5433 | Time-series database |
| **ChromaDB** | 8010 | Vector database |

## 📁 Project Structure

```
data-pipeline-poc/
├── docker-compose.yml          # Service orchestration
├── spark.Dockerfile            # Custom Spark image with Iceberg
├── spark-defaults.conf         # Spark configuration (S3 access, Iceberg)
├── .env                        # Environment variables (credentials)
├── jars/                       # AWS SDK JARs for S3 access
│   ├── hadoop-aws-3.3.4.jar
│   └── aws-java-sdk-bundle-1.12.262.jar
├── init-scripts/
│   └── init-lakehouse.sh      # Auto-initialization script
├── dbt_project/               # dbt transformation project
│   ├── models/
│   │   ├── staging/           # Bronze → Silver transformations
│   │   │   └── silver/
│   │   │       └── dim_uemoa_indicators.sql
│   │   └── gold/              # Silver → Gold transformations
│   │       ├── gold_kpi_uemoa_growth_yoy.sql
│   │       ├── gold_mart_uemoa_external_stability.sql
│   │       ├── gold_mart_uemoa_external_trade.sql
│   │       ├── gold_mart_uemoa_monetary_dashboard.sql
│   │       └── gold_mart_uemoa_public_finance.sql
│   ├── dbt_project.yml
│   └── profiles.yml
├── create_uemoa_table.py      # Script to create Bronze Iceberg table
└── minio_data/                # MinIO storage (auto-created)
    └── lakehouse/
        ├── bronze/            # Raw data from Airbyte (Parquet)
        │   └── indicateurs_economiques_uemoa/
        ├── silver/            # Cleaned data (Iceberg)
        └── gold/              # Analytics-ready data (Iceberg)
```

## 🔄 Data Flow

### Bronze Layer (Raw Data from Airbyte)
- **Source**: Airbyte extracting UEMOA economic indicators
- **Storage**: MinIO `s3a://lakehouse/bronze/indicateurs_economiques_uemoa/`
- **Format**: Parquet files with Snappy compression
- **Table**: `bronze.indicateurs_economiques_uemoa` (Iceberg table created from Parquet)
- **Purpose**: Store raw data immutably with Airbyte metadata
- **Features**: Append-only, timestamped, includes `_airbyte_*` columns

### Silver Layer (Cleaned & Validated Data)
- **Table**: `default_silver.dim_uemoa_indicators`
- **Source**: Bronze Iceberg table
- **Transformations**:
  - Remove Airbyte metadata columns
  - Cast data types appropriately
  - Calculate derived metrics (GDP ratios, balances, etc.)
  - Validate and clean null values
- **Purpose**: Provide clean, standardized dimension table

### Gold Layer (Analytics-Ready Data Marts)
- **Tables**:
  - `gold_kpi_uemoa_growth_yoy`: Year-over-year growth indicators
  - `gold_mart_uemoa_external_stability`: External trade and stability metrics
  - `gold_mart_uemoa_external_trade`: Trade balance and openness indicators
  - `gold_mart_uemoa_monetary_dashboard`: Monetary policy indicators
  - `gold_mart_uemoa_public_finance`: Public finance and debt metrics
- **Purpose**: Optimized tables for specific analytical use cases
- **Transformations**: Business logic, aggregations, KPI calculations

## 🛠️ Common Commands

### Service Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f spark-iceberg

# Restart a service
docker-compose restart spark-iceberg
```

### dbt Commands

```bash
# Run all models (Bronze → Silver → Gold)
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"

# Run specific layer
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select staging"
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select gold"

# Run specific model
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select dim_uemoa_indicators"

# Test data quality
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"

# Generate and serve documentation
docker exec dbt bash -c "cd /usr/app/dbt && dbt docs generate"
docker exec dbt bash -c "cd /usr/app/dbt && dbt docs serve --port 8080"
```

### Spark/Iceberg Commands

```bash
# Connect via Beeline (Spark Thrift Server)
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000

# Execute a query
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT * FROM bronze.indicateurs_economiques_uemoa LIMIT 10;"

# Show all tables
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW TABLES IN bronze;"

# Describe table structure
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "DESCRIBE EXTENDED bronze.indicateurs_economiques_uemoa;"

# Create Bronze table from Airbyte Parquet files
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py"
```

### MinIO Commands

```bash
# List buckets
docker exec mc mc ls bceao-data/

# List files in bronze layer
docker exec mc mc ls bceao-data/lakehouse/bronze/indicateurs_economiques_uemoa/

# Copy file from MinIO
docker exec mc mc cp bceao-data/lakehouse/bronze/indicateurs_economiques_uemoa/file.parquet /tmp/

# View bucket statistics
docker exec mc mc du bceao-data/lakehouse
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Airbyte Parquet files not accessible

**Problem**: `AccessDeniedException` when trying to read Parquet files from MinIO.

**Solution**: Ensure MinIO credentials are correctly set in `.env` and the Spark session has them configured:

```python
# In your PySpark script
spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "SuperSecret123") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .getOrCreate()
```

#### 2. AWS SDK Classes Not Found

**Problem**: `java.lang.NoClassDefFoundError: com/amazonaws/AmazonClientException`

**Solution**: Ensure the JARs are in the `jars/` directory and mounted correctly:
- Check `docker-compose.yml` has `- ./jars:/opt/spark/extra-jars`
- Verify JARs are present: `ls jars/`
- Include JARs when running Spark jobs: `--jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar`

#### 3. dbt Model Fails with Column Not Found

**Problem**: Model references column that doesn't exist in source data.

**Solution**: 
1. Check available columns: `DESCRIBE EXTENDED bronze.indicateurs_economiques_uemoa`
2. Update model to use available columns
3. Verify Airbyte sync includes all expected fields

#### 4. Port Already in Use

**Problem**: `Bind for 0.0.0.0:9000 failed: port is already allocated`

**Solution**:
```bash
# Stop all containers
docker-compose down

# Check what's using the port
netstat -ano | findstr :9000  # Windows
lsof -i :9000                 # macOS/Linux

# Kill the process or change port in docker-compose.yml
```

## 📈 Data Models

### UEMOA Economic Indicators

The pipeline processes the following UEMOA economic indicators:

**Macroeconomic Indicators:**
- GDP (nominal, real growth rate)
- Sectoral weights (primary, secondary, tertiary)
- Inflation rate (average annual CPI)

**Public Finance:**
- Fiscal revenues (total and % of GDP)
- Total expenditures and net lending
- Budget balances (with/without grants)
- Public debt (stock and % of GDP)

**External Trade:**
- Exports (FOB)
- Imports (FOB)
- Trade balance
- Current account balance
- Trade openness degree

**Monetary Indicators:**
- Broad money (M2)
- Monetary emission coverage rate

All indicators are stored at the date level and transformed through the medallion architecture for different analytical purposes.

## 📖 Documentation

### Quick Access

- [📋 Documentation Index](./DOCUMENTATION_INDEX.md) - Complete documentation map
- [🎯 Project Overview](./OVERVIEW.md) - Quick visual summary
- [⚡ Quick Start Guide](./QUICKSTART_FR.md) - Get started in 15 minutes (FR)
- [🔄 Transformation Guide](./TRANSFORMATION_GUIDE_FR.md) - Data transformations (FR)
- [📦 MinIO Structure Guide](./MINIO_STRUCTURE_GUIDE.md) - Organize your data
- [✅ Verification Report](./VERIFICATION_REPORT.md) - System status check
- [📝 Changelog](./CHANGELOG.md) - Version history
- [📋 Version Info](./VERSION_INFO.md) - Detailed version information

### Comprehensive Documentation (French)

For the complete technical documentation in French, see:
- **[README_FR.md](./README_FR.md)** - Complete architecture and setup guide

### Transformation Guides

- [🏦 UEMOA Data Transformations](./UEMOA_TRANSFORMATION_GUIDE_FR.md) - Economic indicators (FR) ⭐ **New**

### Integration Guides

- [🔗 Airbyte-MinIO Integration](./AIRBYTE_MINIO_INTEGRATION.md) - Connect Airbyte to this pipeline

## 🧪 Technologies

- **Apache Iceberg**: Open table format for huge analytic datasets
- **Apache Spark 3.5**: Unified analytics engine
- **dbt**: SQL-based transformation framework
- **MinIO**: High-performance S3-compatible object storage
- **TimescaleDB**: PostgreSQL extension for time-series data
- **ChromaDB**: AI-native open-source vector database

## 📝 License

This project is developed as a proof of concept for BCEAO (Central Bank of West African States).

## 👥 Support

For questions or issues, please refer to the comprehensive French documentation in [README_FR.md](./README_FR.md).
