# Data Pipeline POC - BCEAO

[![Apache Iceberg](https://img.shields.io/badge/Apache%20Iceberg-1.4-blue.svg)](https://iceberg.apache.org/)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-3.5-orange.svg)](https://spark.apache.org/)
[![dbt](https://img.shields.io/badge/dbt-1.7-red.svg)](https://www.getdbt.com/)
[![MinIO](https://img.shields.io/badge/MinIO-S3%20Compatible-red.svg)](https://min.io/)

A modern **Data Lakehouse** implementation using the **Medallion Architecture** (Bronze, Silver, Gold) with Apache Iceberg, Spark, and dbt.

[🇫🇷 Version Française](./README_FR.md) | [⚡ Quick Start](./QUICKSTART_FR.md)

## 🏗️ Architecture Overview

This project implements a complete data pipeline with:

- **Storage Layer**: MinIO (S3-compatible object storage)
- **Table Format**: Apache Iceberg (ACID transactions, time travel, schema evolution)
- **Processing Engine**: Apache Spark with Jupyter Notebook
- **Transformation Orchestration**: dbt (Data Build Tool)
- **Serving Layers**: TimescaleDB (time-series), ChromaDB (vector database)

### Medallion Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                            │
│                    (Data Sources)                             │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    BRONZE LAYER                               │
│            (Raw Data - raw_events, raw_users)                 │
│                   Storage: MinIO (S3)                         │
│                   Format: Apache Iceberg                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │  Transformation (dbt / Spark)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    SILVER LAYER                               │
│         (Cleaned Data - stg_events, stg_users)                │
│          Cleaning, Validation, Deduplication                  │
│                   Format: Apache Iceberg                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │  Aggregation & Enrichment
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    GOLD LAYER                                 │
│          (Analytics Data - fct_events_enriched)               │
│         Fact and dimension tables for analysis                │
│                   Format: Apache Iceberg                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                 CONSUMPTION LAYERS                            │
│    • TimescaleDB (Time Series)                               │
│    • ChromaDB (Vector Search)                                │
│    • Jupyter Notebooks (Ad-hoc Analysis)                     │
│    • BI Dashboards                                           │
└──────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (with at least 8GB RAM)
- Docker Compose
- Available ports: 4040, 8888, 9000, 9001, 8181, 10000, 5433, 8010

### 1. Create `.env` file

```env
# MinIO Configuration
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# PostgreSQL/TimescaleDB Configuration
POSTGRES_DB=datamart
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
```

### 2. Start the services

```bash
# Build images (first time only)
docker-compose build

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Verify installation

- **MinIO Console**: http://localhost:9001
- **Jupyter Notebook**: http://localhost:8888
- **Spark UI**: http://localhost:4040

### 4. Run dbt transformations

```bash
# Execute transformations
docker exec dbt dbt run

# Run tests
docker exec dbt dbt test
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
├── spark-defaults.conf         # Spark configuration
├── init-scripts/
│   └── init-lakehouse.sh      # Auto-initialization script
├── dbt_project/               # dbt transformation project
│   ├── models/
│   │   ├── staging/           # Bronze → Silver transformations
│   │   └── marts/             # Silver → Gold transformations
│   ├── dbt_project.yml
│   └── profiles.yml
└── minio_data/                # MinIO storage (auto-created)
    └── lakehouse/
        ├── bronze/
        ├── silver/
        └── gold/
```

## 🔄 Data Flow

### Bronze Layer (Raw Data)
- **Tables**: `bronze.raw_events`, `bronze.raw_users`
- **Purpose**: Store raw data without transformation
- **Features**: Append-only, immutable, timestamped

### Silver Layer (Cleaned Data)
- **Tables**: `default_silver.stg_events`, `default_silver.stg_users`
- **Purpose**: Cleaned, validated, standardized data
- **Transformations**: Null handling, type casting, validation

### Gold Layer (Analytics Data)
- **Tables**: `default_gold.fct_events_enriched`
- **Purpose**: Enriched data ready for analytics
- **Transformations**: Joins, aggregations, business metrics

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
# Run all models
docker exec dbt dbt run

# Run specific models
docker exec dbt dbt run --select staging

# Test data quality
docker exec dbt dbt test

# Generate documentation
docker exec dbt dbt docs generate
```

### Spark SQL Queries

```bash
# Connect via Beeline
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000

# Execute a query
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.raw_events;"
```

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
