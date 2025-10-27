# Informations de Version - Data Pipeline POC BCEAO

**Version**: 1.0.0  
**Date**: 27 octobre 2025  
**Statut**: Production Ready

---

## 📋 Vue d'Ensemble

Ce projet implémente une architecture **Data Lakehouse** moderne utilisant le pattern **Médaillon** (Bronze, Silver, Gold) avec Apache Iceberg comme format de table.

---

## 🛠️ Stack Technique

### Technologies Principales

| Composant | Version | Rôle |
|-----------|---------|------|
| **Apache Iceberg** | 1.4.x | Format de table ouvert avec support ACID |
| **Apache Spark** | 3.5.x | Moteur de traitement distribué |
| **dbt-spark** | 1.9.0 | Orchestration des transformations SQL |
| **MinIO** | Latest | Stockage objet compatible S3 |
| **TimescaleDB** | pg15 | Base de données time-series |
| **ChromaDB** | Latest | Base de données vectorielle |
| **Iceberg REST Catalog** | Latest | Gestion des métadonnées Iceberg |

### Images Docker

```yaml
# Images utilisées
- minio/minio:latest
- minio/mc:latest
- tabulario/iceberg-rest:latest
- timescale/timescaledb-ha:pg15-latest
- chromadb/chroma:latest
- ghcr.io/dbt-labs/dbt-spark:latest
- Custom: data-pipeline-poc/spark-iceberg:latest (basée sur Apache Spark 3.5)
```

---

## 📊 Architecture des Données

### Namespaces Iceberg

```
✅ bronze                  → Données brutes (raw_events, raw_users)
✅ default_silver          → Données nettoyées (stg_events, stg_users)
✅ default_gold            → Données analytiques (fct_events_enriched)
```

### Tables Principales

#### Bronze Layer (Données Brutes)
```sql
bronze.raw_events (
  event_id INT,
  event_type STRING,
  user_id INT,
  event_timestamp TIMESTAMP,
  event_data STRING
)

bronze.raw_users (
  user_id INT,
  user_name STRING,
  email STRING,
  created_at TIMESTAMP
)
```

#### Silver Layer (Données Nettoyées)
```sql
default_silver.stg_events (
  event_id INT NOT NULL,
  event_type STRING,
  user_id INT,
  event_timestamp TIMESTAMP,
  event_data STRING,
  dbt_loaded_at TIMESTAMP
)

default_silver.stg_users (
  user_id INT NOT NULL,
  user_name STRING,
  user_email STRING,
  created_at TIMESTAMP,
  dbt_loaded_at TIMESTAMP
)
```

#### Gold Layer (Données Analytiques)
```sql
default_gold.fct_events_enriched (
  event_id INT NOT NULL,
  event_type STRING,
  event_timestamp TIMESTAMP,
  event_data STRING,
  user_id INT,
  user_name STRING,
  user_email STRING,
  user_created_at TIMESTAMP,
  dbt_loaded_at TIMESTAMP
)
```

---

## 🔧 Configuration

### Ports Exposés

| Service | Port(s) | Description |
|---------|---------|-------------|
| MinIO Console | 9001 | Interface web MinIO |
| MinIO API | 9000 | API S3 MinIO |
| Spark UI | 4040 | Interface Spark Thrift Server |
| Jupyter Notebook | 8888 | Notebooks interactifs |
| Spark Thrift Server | 10000 | JDBC/ODBC endpoint |
| Iceberg REST | 8181 | Catalogue Iceberg REST |
| TimescaleDB | 5433 | PostgreSQL/TimescaleDB |
| ChromaDB | 8010 | API ChromaDB |

### Variables d'Environnement

```env
# MinIO
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# TimescaleDB
POSTGRES_DB=datamart
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
```

### Configuration Spark (spark-defaults.conf)

```properties
# Iceberg Configuration
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.spark_catalog.type=rest
spark.sql.catalog.spark_catalog.uri=http://rest:8181
spark.sql.catalog.spark_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO
spark.sql.catalog.spark_catalog.warehouse=s3://lakehouse/
spark.sql.catalog.spark_catalog.s3.endpoint=http://minio:9000
spark.sql.catalog.spark_catalog.s3.path-style-access=true

# S3 Configuration
spark.hadoop.fs.s3a.endpoint=http://minio:9000
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false
```

### Configuration dbt (dbt_project.yml)

```yaml
name: 'data_pipeline_poc'
version: '1.0.0'
config-version: 2

models:
  data_pipeline_poc:
    +materialized: table
    +file_format: iceberg
    
    staging:
      +schema: default_silver
      
    marts:
      +schema: default_gold
```

### Configuration dbt Profiles (profiles.yml)

```yaml
data_pipeline_poc:
  target: dev
  outputs:
    dev:
      type: spark
      method: thrift
      host: spark-iceberg
      port: 10000
      user: root
      schema: default
      connect_retries: 3
      connect_timeout: 10
```

---

## 📁 Structure du Projet

```
data-pipeline-poc/
├── docker-compose.yml              # Orchestration des services
├── spark.Dockerfile                # Image Spark personnalisée
├── spark-defaults.conf             # Configuration Spark
├── .env                            # Variables d'environnement
│
├── init-scripts/
│   └── init-lakehouse.sh          # Script d'initialisation auto
│
├── dbt_project/
│   ├── dbt_project.yml            # Config projet dbt
│   ├── profiles.yml               # Profils connexion dbt
│   ├── models/
│   │   ├── staging/               # Bronze → Silver
│   │   │   ├── sources.yml
│   │   │   ├── stg_events.sql
│   │   │   └── stg_users.sql
│   │   └── marts/                 # Silver → Gold
│   │       ├── schema.yml
│   │       └── fct_events_enriched.sql
│   └── dbt_packages/
│       └── dbt_utils/             # Package dbt utils
│
├── minio_data/                     # Stockage MinIO (volumes)
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── lakehouse/                 # Métadonnées Iceberg
│
├── spark_app_data/                 # Notebooks Jupyter
├── spark_lakehouse_data/           # Données lakehouse
├── postgres_data/                  # Données TimescaleDB
├── chroma_data/                    # Données ChromaDB
└── dbt_data/                       # Cache dbt
│
└── Documentation/
    ├── README.md                   # Documentation principale (EN)
    ├── README_FR.md                # Documentation complète (FR)
    ├── QUICKSTART_FR.md            # Guide démarrage rapide
    ├── TRANSFORMATION_GUIDE_FR.md  # Guide transformations
    ├── AIRBYTE_MINIO_INTEGRATION.md # Integration Airbyte
    ├── MINIO_STRUCTURE_GUIDE.md    # Organisation MinIO
    ├── VERIFICATION_REPORT.md      # Rapport de vérification
    └── VERSION_INFO.md             # Ce document
```

---

## 🚀 Commandes Essentielles

### Gestion du Système

```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Voir les logs
docker-compose logs -f spark-iceberg

# Arrêter le système
docker-compose down

# Reconstruction complète
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### dbt - Transformations

```bash
# Exécuter toutes les transformations
docker exec dbt dbt run

# Exécuter uniquement staging
docker exec dbt dbt run --select staging

# Exécuter uniquement marts
docker exec dbt dbt run --select marts

# Tester la qualité des données
docker exec dbt dbt test

# Vérifier la connexion
docker exec dbt dbt debug

# Générer la documentation
docker exec dbt dbt docs generate
```

### Spark SQL - Requêtes

```bash
# Lister les namespaces
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW NAMESPACES;"

# Lister les tables d'un namespace
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN bronze;"

# Compter les événements
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.raw_events;"

# Requête sur les données enrichies
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT * FROM default_gold.fct_events_enriched LIMIT 10;"

# Mode interactif Beeline
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000
```

### MinIO - Gestion du Stockage

```bash
# Accès web : http://localhost:9001
# Credentials : voir fichier .env

# Lister les buckets via CLI
docker exec mc mc ls bceao-data/

# Vérifier le contenu de lakehouse
docker exec mc mc ls bceao-data/lakehouse/
```

---

## 📊 Métriques du Système

### Données de Test

- **Bronze.raw_events**: 20 événements de test
- **Bronze.raw_users**: 6 utilisateurs de test
- **Silver.stg_events**: 20 événements nettoyés
- **Silver.stg_users**: 6 utilisateurs nettoyés
- **Gold.fct_events_enriched**: 20 événements enrichis avec info utilisateurs

### Performance

- **Temps d'initialisation**: ~2 minutes
- **Temps de transformation dbt**: ~10-30 secondes
- **Mémoire requise**: Minimum 8GB RAM
- **Espace disque**: ~5GB (incluant toutes les images Docker)

---

## 🎯 Fonctionnalités Principales

### ✅ Implémenté

- [x] Architecture Médaillon (Bronze, Silver, Gold)
- [x] Tables Iceberg avec support ACID
- [x] Transformations SQL avec dbt
- [x] Jupyter Notebooks pour analyses ad-hoc
- [x] Spark Thrift Server pour connexions JDBC/ODBC
- [x] Stockage S3 avec MinIO
- [x] Catalogue Iceberg REST
- [x] TimescaleDB pour time-series
- [x] ChromaDB pour recherche vectorielle
- [x] Initialisation automatique du lakehouse
- [x] Données de test pré-chargées
- [x] Tests de qualité de données dbt

### 🔄 Intégrations Possibles

- [ ] Airbyte pour ingestion de données
- [ ] Superset/Metabase pour visualisation
- [ ] Airflow pour orchestration
- [ ] Great Expectations pour data quality
- [ ] MLflow pour ML lifecycle

---

## 📖 Documentation

### Guides Disponibles

1. **README.md** - Vue d'ensemble et quick start (EN)
2. **README_FR.md** - Documentation complète (FR)
3. **QUICKSTART_FR.md** - Guide de démarrage rapide
4. **TRANSFORMATION_GUIDE_FR.md** - Guide des transformations détaillé
5. **AIRBYTE_MINIO_INTEGRATION.md** - Intégration avec Airbyte
6. **MINIO_STRUCTURE_GUIDE.md** - Organisation des buckets MinIO
7. **VERIFICATION_REPORT.md** - Rapport de vérification système

### Accès Web

| Interface | URL | Authentification |
|-----------|-----|------------------|
| MinIO Console | http://localhost:9001 | admin / password123 |
| Jupyter Notebook | http://localhost:8888 | Aucune (désactivée) |
| Spark UI | http://localhost:4040 | Aucune |
| Iceberg REST | http://localhost:8181 | Aucune |
| ChromaDB | http://localhost:8010 | Aucune |

---

## 🐛 Dépannage

### Problèmes Courants

**Services ne démarrent pas**
```bash
docker-compose logs
docker-compose down
docker-compose up -d
```

**dbt ne peut pas se connecter**
```bash
# Vérifier que Thrift Server est prêt
docker-compose logs spark-iceberg | grep "ThriftBinaryCLIService"
# Attendre 2 minutes après le démarrage
docker exec dbt dbt debug
```

**Jupyter n'est pas accessible**
```bash
docker exec spark-iceberg cat /opt/spark/logs/jupyter.log
docker-compose restart spark-iceberg
```

---

## 📝 Notes de Version

### Version 1.0.0 (27 octobre 2025)

**Nouvelles fonctionnalités**:
- ✅ Architecture complète Bronze-Silver-Gold
- ✅ Intégration dbt avec Iceberg
- ✅ Documentation complète en français
- ✅ Scripts d'initialisation automatique
- ✅ Données de test pré-chargées

**Améliorations**:
- ✨ Configuration Spark optimisée pour Iceberg
- ✨ Support complet des transformations SQL
- ✨ Tests de qualité de données

**Corrections**:
- 🐛 Résolution des problèmes de connexion dbt
- 🐛 Configuration correcte du catalogue Iceberg REST
- 🐛 Gestion des chemins S3 dans MinIO

---

## 👥 Contributeurs

Projet développé pour la **BCEAO** (Banque Centrale des États de l'Afrique de l'Ouest)

---

## 📚 Ressources Externes

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [dbt Documentation](https://docs.getdbt.com/)
- [MinIO Documentation](https://min.io/docs/)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [ChromaDB Documentation](https://docs.trychroma.com/)

---

**Dernière mise à jour**: 27 octobre 2025
