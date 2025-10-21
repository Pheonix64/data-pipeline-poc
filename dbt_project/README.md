# dbt Project - Data Pipeline POC

This dbt project transforms data in the Data Lakehouse using Apache Spark and Iceberg tables.

## Architecture

```
Bronze (Raw Data)  →  Silver (Staging)  →  Gold (Marts)
  raw_events      →    stg_events      →  fct_events_enriched
  raw_users       →    stg_users       →
```

## Project Structure

```
dbt_project/
├── dbt_project.yml          # Project configuration
├── profiles.yml             # Connection profiles
├── models/
│   ├── staging/            # Silver layer transformations
│   │   ├── sources.yml     # Source definitions
│   │   ├── stg_events.sql  # Staging events table
│   │   └── stg_users.sql   # Staging users table
│   └── marts/              # Gold layer analytics
│       ├── schema.yml      # Model documentation
│       └── fct_events_enriched.sql  # Enriched events fact table
├── macros/                 # Custom Jinja macros
└── tests/                  # Data quality tests
```

## Connection

dbt connects to the Spark Thrift Server running in the `spark-iceberg` container:
- **Host**: spark-iceberg
- **Port**: 10000
- **Method**: thrift
- **Schema**: default

## Running dbt

### Check Connection
```bash
docker exec dbt dbt debug
```

### Run All Models
```bash
docker exec dbt dbt run
```

### Run Specific Models
```bash
# Run only staging models
docker exec dbt dbt run --select staging

# Run only marts
docker exec dbt dbt run --select marts

# Run a specific model
docker exec dbt dbt run --select stg_events
```

### Test Data Quality
```bash
docker exec dbt dbt test
```

### Generate Documentation
```bash
docker exec dbt dbt docs generate
docker exec dbt dbt docs serve
```

## Models

### Staging Models (Silver Layer)

**stg_events**
- Cleans and standardizes raw event data from bronze.raw_events
- Materialized as: Iceberg table
- Location: default_default_silver.stg_events

**stg_users**
- Cleans and standardizes raw user data from bronze.raw_users
- Materialized as: Iceberg table
- Location: default_default_silver.stg_users

### Mart Models (Gold Layer)

**fct_events_enriched**
- Joins event data with user information for analytics
- Materialized as: Iceberg table
- Location: default_default_gold.fct_events_enriched
- Contains: event details + user profile data

## Configuration

### File Format
All models use **Apache Iceberg** as the file format for:
- ACID transactions
- Time travel capabilities
- Schema evolution
- Partition evolution

### Materialization Strategy
- **Staging**: Table (Iceberg)
- **Marts**: Table (Iceberg)

### Schemas/Namespaces
- **Bronze**: bronze
- **Silver**: default_default_silver
- **Gold**: default_default_gold

## Best Practices

1. **Incremental Models**: For large datasets, consider using incremental materialization
2. **Partitioning**: Add partition configuration for large tables
3. **Tests**: Always add data quality tests to your models
4. **Documentation**: Document all models in schema.yml files
5. **Macros**: Create reusable macros for common transformations

## Troubleshooting

### Connection Issues
If dbt cannot connect to Spark:
```bash
# Check if Thrift Server is running
docker exec spark-iceberg netstat -tuln | grep 10000

# Check Spark logs
docker logs spark-iceberg --tail 50
```

### Model Failures
Check the compiled SQL:
```bash
docker exec dbt cat target/compiled/data_pipeline_poc/models/<model_name>.sql
```

## Next Steps

1. Add incremental models for large datasets
2. Implement data quality tests
3. Add snapshots for slowly changing dimensions
4. Create custom macros for business logic
5. Set up CI/CD pipeline for automated testing
