# ARCHITECTURE TECHNIQUE - Data Pipeline POC BCEAO

## Vue d'ensemble du système

Ce document décrit l'architecture complète du pipeline de données pour l'analyse des indicateurs économiques de l'UEMOA (Union Économique et Monétaire Ouest-Africaine).

## Architecture en couches (Medallion Architecture)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SOURCES DE DONNÉES                            │
│                    (API BCEAO, Fichiers CSV, etc.)                   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   AIRBYTE    │ Ingestion des données
                    │  (ETL Tool)  │ Format: Parquet + Snappy compression
                    └──────┬───────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         BRONZE LAYER                                 │
│                     (Raw Data - Parquet)                             │
│                                                                       │
│  MinIO S3: s3a://lakehouse/bronze/                                  │
│  ├── indicateurs_economiques_uemoa/                                 │
│  │   ├── 2024_01_15_1705324800_uuid1.parquet                       │
│  │   ├── 2024_01_16_1705411200_uuid2.parquet                       │
│  │   └── ...                                                         │
│                                                                       │
│  Apache Iceberg Table:                                               │
│  ├── bronze.indicateurs_economiques_uemoa                           │
│  │   Colonnes: pays, annee, trimestre, pib_nominal, pib_reel,      │
│  │            taux_croissance, solde_budgetaire, dette_publique,    │
│  │            exportations, importations, masse_monetaire, etc.     │
│  │   Rows: ~20-100 (selon période d'ingestion)                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           │ dbt transformation (Silver layer models)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SILVER LAYER                                 │
│                  (Cleaned & Transformed Data)                        │
│                                                                       │
│  Iceberg Tables (default_silver namespace):                         │
│  ├── dim_uemoa_indicators                                           │
│  │   ├── Data types standardized (DECIMAL, DATE, STRING)           │
│  │   ├── Column naming standardized                                 │
│  │   ├── NULL handling                                              │
│  │   ├── Data quality checks applied                                │
│  │   └── Business rules enforcement                                 │
│  │                                                                   │
│  ├── stg_events (for web analytics)                                 │
│  └── stg_users (for user dimension)                                 │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           │ dbt transformation (Gold layer models)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          GOLD LAYER                                  │
│                    (Analytics-Ready Marts)                           │
│                                                                       │
│  Iceberg Tables (default_gold namespace):                           │
│                                                                       │
│  1. gold_kpi_uemoa_growth_yoy                                       │
│     ├── Croissance PIB YoY par pays et trimestre                    │
│     ├── Métriques: pib_reel_yoy_pct, pib_nominal_yoy_pct           │
│     └── Granularité: pays, année, trimestre                         │
│                                                                       │
│  2. gold_mart_uemoa_external_stability                              │
│     ├── Indicateurs de stabilité externe                            │
│     ├── Métriques: ratio_endettement, service_dette_pct,            │
│     │   taux_couverture_importations, ouverture_commerciale        │
│     └── Granularité: pays, année, trimestre                         │
│                                                                       │
│  3. gold_mart_uemoa_external_trade                                  │
│     ├── Balance commerciale et flux d'échanges                      │
│     ├── Métriques: balance_commerciale, taux_couverture,            │
│     │   exports_imports_ratio                                       │
│     └── Granularité: pays, année, trimestre                         │
│                                                                       │
│  4. gold_mart_uemoa_monetary_dashboard                              │
│     ├── Agrégats monétaires (M1, M2, M3)                           │
│     ├── Métriques: masse_monetaire_variation_pct,                   │
│     │   credits_economie_pib_ratio                                  │
│     └── Granularité: pays, année, trimestre                         │
│                                                                       │
│  5. gold_mart_uemoa_public_finance                                  │
│     ├── Finances publiques et endettement                           │
│     ├── Métriques: solde_budgetaire_pib_pct,                        │
│     │   dette_publique_pib_pct, recettes_depenses_pct              │
│     └── Granularité: pays, année, trimestre                         │
│                                                                       │
│  6. fct_events_enriched (pour analytics web)                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Stack technologique détaillé

### 1. Couche de stockage (Storage Layer)

#### MinIO S3-Compatible Object Storage

**Rôle**: Data Lake backend pour tous les fichiers Parquet et métadonnées Iceberg

**Configuration**:
```yaml
Service: minio
Port: 9000 (API), 9001 (Console)
Credentials: 
  - Access Key: admin
  - Secret Key: SuperSecret123
Buckets:
  - lakehouse (main data lake)
  - bronze (raw data - legacy)
  - silver (cleaned data - legacy)
  - gold (analytics marts - legacy)
```

**Avantages**:
- Compatible S3 API
- Interface web intuitive
- Haute disponibilité
- Versioning des objets
- Policies de rétention
- Encryption au repos possible

### 2. Couche de calcul (Compute Layer)

#### Apache Spark 3.5.5

**Rôle**: Moteur de traitement distribué pour lecture Parquet et gestion Iceberg

**Configuration**:
```yaml
Service: spark-iceberg
Ports:
  - 8888 (Jupyter)
  - 4040 (Spark UI)
  - 10000 (HiveServer2/Beeline)
Memory: 4GB driver, 2GB executor
Cores: 2
```

**Extensions installées**:
- Apache Iceberg 1.8.1 (Spark Runtime)
- Hadoop AWS 3.3.4 (S3A filesystem)
- AWS SDK Bundle 1.12.262 (S3 client)
- dbt-spark 1.9.0

**Configuration critique** (`spark-defaults.conf`):
```properties
# Iceberg Catalog
spark.sql.catalog.local=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.local.type=rest
spark.sql.catalog.local.uri=http://iceberg-rest:8181

# S3 Access
spark.hadoop.fs.s3a.endpoint=http://minio:9000
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.access.key=${MINIO_ROOT_USER}
spark.hadoop.fs.s3a.secret.key=${MINIO_ROOT_PASSWORD}
```

### 3. Couche de catalogue (Catalog Layer)

#### Apache Iceberg REST Catalog

**Rôle**: Gestion centralisée des métadonnées des tables Iceberg

**Configuration**:
```yaml
Service: iceberg-rest
Port: 8181
Warehouse: s3a://lakehouse
Catalog Backend: In-memory (dev) ou JDBC (prod)
```

**Fonctionnalités**:
- Schema evolution sans downtime
- Time travel (requêtes sur versions historiques)
- Partition evolution (changement de stratégie de partitionnement)
- Hidden partitioning (pas de prédicats de partition dans les requêtes)
- ACID transactions
- Snapshot isolation

### 4. Couche de transformation (Transformation Layer)

#### dbt (Data Build Tool) 1.9.0

**Rôle**: Orchestration SQL des transformations Bronze → Silver → Gold

**Configuration**:
```yaml
Service: dbt
Working Directory: /usr/app/dbt
Profile: profiles.yml
  - Target: dev
  - Type: spark
  - Method: thrift
  - Host: localhost (via network)
  - Port: 10000
```

**Modèles dbt**:

**Bronze → Silver**:
```sql
-- models/staging/stg_uemoa/dim_uemoa_indicators.sql
SELECT
    pays,
    annee,
    trimestre,
    CAST(pib_nominal_milliards_fcfa AS DECIMAL(18,2)) AS pib_nominal,
    CAST(pib_reel_milliards_fcfa AS DECIMAL(18,2)) AS pib_reel,
    -- ... standardization, type conversion, cleaning
FROM {{ source('bronze', 'indicateurs_economiques_uemoa') }}
WHERE pays IS NOT NULL
  AND annee IS NOT NULL
```

**Silver → Gold (Example)**:
```sql
-- models/marts/gold_kpi_uemoa_growth_yoy.sql
WITH current_period AS (
    SELECT * FROM {{ ref('dim_uemoa_indicators') }}
),
previous_year AS (
    SELECT 
        pays,
        annee + 1 AS annee,
        trimestre,
        pib_reel AS pib_reel_prev_year
    FROM {{ ref('dim_uemoa_indicators') }}
)
SELECT
    c.pays,
    c.annee,
    c.trimestre,
    c.pib_reel,
    p.pib_reel_prev_year,
    CASE 
        WHEN p.pib_reel_prev_year > 0 
        THEN ((c.pib_reel - p.pib_reel_prev_year) / p.pib_reel_prev_year) * 100
        ELSE NULL
    END AS pib_reel_yoy_pct
FROM current_period c
LEFT JOIN previous_year p
    ON c.pays = p.pays
    AND c.annee = p.annee
    AND c.trimestre = p.trimestre
```

**Lineage Graph**:
```
bronze.indicateurs_economiques_uemoa
    │
    ├──> dim_uemoa_indicators (Silver)
    │       │
    │       ├──> gold_kpi_uemoa_growth_yoy
    │       ├──> gold_mart_uemoa_external_stability
    │       ├──> gold_mart_uemoa_external_trade
    │       ├──> gold_mart_uemoa_monetary_dashboard
    │       └──> gold_mart_uemoa_public_finance
    │
bronze.raw_events
    │
    └──> stg_events (Silver)
            │
            └──> fct_events_enriched (Gold)
    
bronze.raw_users
    │
    └──> stg_users (Silver)
```

### 5. Couche d'ingestion (Ingestion Layer)

#### Airbyte (External - not in docker-compose)

**Rôle**: Extraction et chargement des données sources vers Bronze layer

**Configuration Source**:
- Type: REST API / File / Database
- Fréquence: Quotidienne/Hebdomadaire
- Format de sortie: Parquet avec compression Snappy

**Configuration Destination (MinIO)**:
```yaml
Destination Type: S3
S3 Bucket Name: lakehouse
S3 Bucket Path: bronze/indicateurs_economiques_uemoa
S3 Endpoint: http://minio:9000
Access Key ID: admin
Secret Access Key: SuperSecret123
S3 Path Format: ${NAMESPACE}/${STREAM_NAME}/${YEAR}_${MONTH}_${DAY}_${EPOCH}_${UUID}.parquet
Output Format: Parquet (Columnar Storage)
Compression Codec: SNAPPY
Block Size: 128 MB
Page Size: 1 MB
Dictionary Encoding: true
```

**Pourquoi Parquet + Snappy?**
- Compression rapide (~2-3x) avec décompression rapide
- Format colonnaire optimisé pour analytics (lecture sélective de colonnes)
- Compatible avec Spark, Iceberg, Hive, Presto
- Schema evolution support
- Predicate pushdown

### 6. Services complémentaires

#### TimescaleDB (PostgreSQL avec extension temporelle)

**Rôle**: Stockage de séries temporelles pour analytics avancées

**Configuration**:
```yaml
Service: timescaledb
Port: 5433
Database: monetary_policy_dm
Credentials: postgres/PostgresPass123
```

**Use Case**:
- Stockage de KPI agrégés pour dashboarding rapide
- Analytics temporelles avec window functions optimisées
- Alerting sur anomalies

#### ChromaDB

**Rôle**: Vector database pour RAG (Retrieval-Augmented Generation)

**Configuration**:
```yaml
Service: chromadb
Port: 8010
Persistence: ./chroma_data
```

**Use Case**:
- Stockage d'embeddings de documents économiques
- Recherche sémantique dans rapports BCEAO
- Q&A avec LLM sur indicateurs

## Flux de données détaillé

### Étape 1: Ingestion (Airbyte → MinIO)

```
Source API BCEAO
    │
    │ HTTP GET /api/indicators?country=BEN&year=2024
    │
    ▼
Airbyte Connector
    │ Transformation: JSON → Parquet
    │ Compression: Snappy
    │ Partitioning: /year/month/day
    │
    ▼
MinIO S3
    s3a://lakehouse/bronze/indicateurs_economiques_uemoa/
        2024_01_15_1705324800_abc123.parquet (150 KB)
        2024_01_16_1705411200_def456.parquet (145 KB)
```

**Fréquence**: Quotidienne à 2h00 UTC
**Volume**: ~5-10 MB/jour (non compressé)
**Retention**: Illimitée (Bronze = raw data preservation)

### Étape 2: Catalogage Iceberg (PySpark → Iceberg REST)

```python
# create_uemoa_table.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "SuperSecret123") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.local.type", "rest") \
    .config("spark.sql.catalog.local.uri", "http://iceberg-rest:8181") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .getOrCreate()

# Lecture des Parquet files
df = spark.read.parquet("s3a://lakehouse/bronze/indicateurs_economiques_uemoa/")

# Création table Iceberg avec schema inference
df.writeTo("local.bronze.indicateurs_economiques_uemoa") \
    .using("iceberg") \
    .createOrReplace()

print("Table bronze.indicateurs_economiques_uemoa created successfully!")
```

**Résultat**:
- Table Iceberg enregistrée dans REST catalog
- Métadonnées stockées dans `s3a://lakehouse/bronze/indicateurs_economiques_uemoa/metadata/`
- Manifests lists et snapshot metadata créés
- Schema version 1 enregistré

### Étape 3: Transformation Silver (dbt run)

```bash
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select dim_uemoa_indicators"
```

**Processus**:
1. dbt compile le SQL Jinja en requête Spark SQL
2. Connexion à Spark via Thrift (HiveServer2)
3. Exécution de la transformation:
   ```sql
   CREATE OR REPLACE TABLE default_silver.dim_uemoa_indicators
   USING iceberg
   AS
   SELECT
       pays,
       annee,
       trimestre,
       CAST(pib_nominal_milliards_fcfa AS DECIMAL(18,2)) AS pib_nominal,
       -- ... autres transformations
   FROM local.bronze.indicateurs_economiques_uemoa
   WHERE pays IS NOT NULL AND annee >= 2010
   ```
4. Iceberg crée nouveau snapshot
5. Métadonnées mises à jour atomiquement

**Résultat**:
- Table `default_silver.dim_uemoa_indicators` créée/mise à jour
- Snapshot ID: `8901234567890123456`
- Lignes insérées: ~500
- Durée: ~5-10 secondes

### Étape 4: Transformation Gold (dbt run)

```bash
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select gold_*"
```

**Processus pour chaque mart**:
1. Lecture de `dim_uemoa_indicators` (Silver)
2. Application de business logic (KPI calculations)
3. Agrégations et jointures
4. Création table Gold avec partitioning

**Exemple - gold_mart_uemoa_external_stability**:
```sql
CREATE OR REPLACE TABLE default_gold.gold_mart_uemoa_external_stability
USING iceberg
PARTITIONED BY (annee)
AS
SELECT
    pays,
    annee,
    trimestre,
    dette_publique_totale_milliards_fcfa,
    pib_nominal_milliards_fcfa,
    (dette_publique_totale_milliards_fcfa / NULLIF(pib_nominal_milliards_fcfa, 0)) * 100 
        AS ratio_endettement_pct,
    -- ... autres métriques
FROM {{ ref('dim_uemoa_indicators') }}
WHERE pib_nominal_milliards_fcfa > 0
```

**Résultat**:
- 5 tables Gold créées
- Partitionnées par `annee` pour query performance
- Prêtes pour consommation par dashboards

## Monitoring et observabilité

### Métriques Spark

**Spark UI** (http://localhost:4040):
- DAG Visualization
- Stage duration
- Task metrics (shuffle read/write)
- Memory usage
- Failed tasks

**Logs Spark**:
```bash
docker logs spark-iceberg | grep ERROR
```

### Métriques dbt

**dbt Logs**:
```bash
docker exec dbt bash -c "cat /usr/app/dbt/logs/dbt.log"
```

**dbt Artifacts**:
- `manifest.json`: Full project compilation
- `run_results.json`: Execution results
- `catalog.json`: Table metadata

### Métriques MinIO

**MinIO Console** (http://localhost:9001):
- Bucket size
- Object count
- Request metrics (GET/PUT)
- Bandwidth usage

**MinIO mc client**:
```bash
docker exec mc mc admin info bceao-data
```

## Sécurité

### Authentification

**MinIO**: Access Key + Secret Key
**Spark**: Pas d'auth (dev mode)
**dbt**: Via Spark Thrift (pas d'auth additionnelle)

### Encryption

**En transit**: HTTP (dev) - HTTPS recommandé pour prod
**Au repos**: Non activé (dev) - Encryption S3 recommandée pour prod

### Network Isolation

**Docker Networks**:
- Services isolés dans réseau bridge `data-pipeline-poc_default`
- Seuls ports exposés: 9001, 8888, 4040, 8181, 10000

## Performance

### Tuning Spark

**Pour workloads lourds** (>1GB data):
```properties
spark.driver.memory=8g
spark.executor.memory=16g
spark.sql.shuffle.partitions=400
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
```

### Tuning Iceberg

**Optimisation read performance**:
```sql
-- Compaction de petits fichiers
CALL local.system.rewrite_data_files(
    table => 'bronze.indicateurs_economiques_uemoa',
    strategy => 'binpack',
    options => map('target-file-size-bytes','536870912')
);

-- Expiration de vieux snapshots
CALL local.system.expire_snapshots(
    table => 'bronze.indicateurs_economiques_uemoa',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 100
);
```

### Tuning MinIO

**Configuration production**:
```yaml
environment:
  - MINIO_STORAGE_CLASS_STANDARD=EC:2  # Erasure coding
  - MINIO_COMPRESS_ENABLED=on
  - MINIO_COMPRESS_EXTENSIONS=.csv,.log
```

## Évolutivité

### Scaling Horizontal

**Spark Cluster** (via Kubernetes ou YARN):
- Master node: Coordination
- Worker nodes: Parallel execution
- Dynamic allocation enabled

**MinIO Distributed**:
- Multi-node setup (4+ nodes)
- Distributed erasure coding
- High availability

### Scaling Vertical

**Spark**:
- Augmenter driver/executor memory
- Augmenter cores per executor

**MinIO**:
- Ajouter disks pour storage expansion

## Disaster Recovery

### Backups

**MinIO Data**:
```bash
docker exec mc mc mirror --preserve bceao-data/lakehouse /backup/lakehouse
```

**Iceberg Metadata**:
- Automatiquement versionné dans snapshots
- Rollback possible via time travel

### Recovery

**Restauration MinIO**:
```bash
docker exec mc mc mirror /backup/lakehouse bceao-data/lakehouse
```

**Rollback Iceberg**:
```sql
CALL local.system.rollback_to_snapshot(
    'bronze.indicateurs_economiques_uemoa',
    8901234567890123456
);
```

## Références

- [Apache Iceberg Documentation](https://iceberg.apache.org/docs/latest/)
- [Apache Spark SQL Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)
- [dbt Documentation](https://docs.getdbt.com/)
- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
- [Airbyte Documentation](https://docs.airbyte.com/)
