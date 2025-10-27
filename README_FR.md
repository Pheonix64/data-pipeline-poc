# Documentation du Projet - Data Pipeline POC BCEAO

## Vue d'Ensemble

Ce projet implémente un **pipeline de données moderne** (Data Lakehouse) utilisant l'architecture **Médaillon** (Bronze, Silver, Gold) avec Apache Iceberg, Spark et dbt.

## Architecture Générale

```
┌─────────────────────────────────────────────────────────────────┐
│                    COUCHE INGESTION                              │
│                  (Sources de données)                            │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    COUCHE BRONZE                                 │
│              (Données brutes - raw_events, raw_users)            │
│                   Stockage: MinIO (S3)                           │
│                   Format: Apache Iceberg                         │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │  Transformation (dbt / Spark)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    COUCHE SILVER                                 │
│         (Données nettoyées - stg_events, stg_users)              │
│              Nettoyage, Validation, Dédoublonnage                │
│                   Format: Apache Iceberg                         │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │  Agrégation & Enrichissement
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    COUCHE GOLD                                   │
│              (Données analytiques - fct_events_enriched)         │
│           Tables de faits et dimensions pour l'analyse           │
│                   Format: Apache Iceberg                         │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                 COUCHES DE CONSOMMATION                          │
│    • TimescaleDB (Séries temporelles)                           │
│    • ChromaDB (Recherche vectorielle)                           │
│    • Jupyter Notebooks (Analyse ad-hoc)                         │
│    • Tableaux de bord BI                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Composants du Système

### 1. **MinIO** - Stockage de Données (S3-Compatible)
- **Rôle**: Data Lake - Stockage objet pour toutes les données
- **Port Console**: 9001
- **Port API**: 9000
- **Buckets**:
  - `bronze/`: Données brutes
  - `silver/`: Données nettoyées
  - `gold/`: Données analytiques
  - `lakehouse/`: Métadonnées Iceberg

### 2. **Apache Iceberg REST Catalog**
- **Rôle**: Gestion des métadonnées des tables Iceberg
- **Port**: 8181
- **Fonctionnalités**:
  - Versioning des schémas
  - Time travel (voyage dans le temps)
  - ACID transactions

### 3. **Spark avec Iceberg** 
- **Rôle**: Moteur de transformation de données
- **Ports**:
  - 4040: Spark UI
  - 8888: Jupyter Notebook
  - 10000: Thrift Server (JDBC/ODBC)
- **Outils disponibles**:
  - PySpark
  - Spark SQL
  - dbt-spark

### 4. **dbt (Data Build Tool)**
- **Rôle**: Orchestration des transformations SQL
- **Conteneur**: Dédié pour les transformations batch
- **Connexion**: Via Spark Thrift Server

### 5. **TimescaleDB**
- **Rôle**: Base de données pour séries temporelles
- **Port**: 5433
- **Usage**: Données time-series pour analyses rapides

### 6. **ChromaDB**
- **Rôle**: Base de données vectorielle
- **Port**: 8010
- **Usage**: Recherche sémantique et embeddings

## Architecture Médaillon Détaillée

### 🥉 **Couche Bronze** (Données Brutes)

**Principe**: Conservation des données dans leur format original sans transformation.

**Caractéristiques**:
- Données brutes, non modifiées
- Format source préservé
- Horodatage d'ingestion
- Pas de validation stricte
- Schéma flexible

**Tables actuelles**:
```sql
-- bronze.raw_events
CREATE TABLE bronze.raw_events (
    event_id INT,
    event_type STRING,
    user_id INT,
    event_timestamp TIMESTAMP,
    event_data STRING
) USING iceberg;

-- bronze.raw_users
CREATE TABLE bronze.raw_users (
    user_id INT,
    user_name STRING,
    email STRING,
    created_at TIMESTAMP
) USING iceberg;
```

### 🥈 **Couche Silver** (Données Nettoyées)

**Principe**: Données nettoyées, validées et standardisées.

**Transformations appliquées**:
- Nettoyage des valeurs nulles
- Standardisation des formats
- Validation des données
- Dédoublonnage
- Ajout de métadonnées de traçabilité

**Tables actuelles**:
```sql
-- default_default_silver.stg_events
CREATE TABLE default_default_silver.stg_events (
    event_id INT NOT NULL,
    event_type STRING,
    user_id INT,
    event_timestamp TIMESTAMP,
    event_data STRING,
    dbt_loaded_at TIMESTAMP  -- Traçabilité
) USING iceberg;

-- default_default_silver.stg_users
CREATE TABLE default_default_silver.stg_users (
    user_id INT NOT NULL,
    user_name STRING,
    user_email STRING,  -- Renommé depuis 'email'
    created_at TIMESTAMP,
    dbt_loaded_at TIMESTAMP
) USING iceberg;
```

### 🥇 **Couche Gold** (Données Analytiques)

**Principe**: Données enrichies et agrégées pour l'analyse.

**Transformations appliquées**:
- Jointures entre tables
- Agrégations métier
- Calculs de métriques
- Dénormalisation pour performance
- Modélisation dimensionnelle

**Tables actuelles**:
```sql
-- default_default_gold.fct_events_enriched
CREATE TABLE default_default_gold.fct_events_enriched (
    event_id INT NOT NULL,
    event_type STRING,
    event_timestamp TIMESTAMP,
    event_data STRING,
    user_id INT,
    user_name STRING,        -- Enrichi depuis users
    user_email STRING,       -- Enrichi depuis users
    user_created_at TIMESTAMP, -- Enrichi depuis users
    dbt_loaded_at TIMESTAMP
) USING iceberg;
```

## Points d'Accès au Système

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Jupyter Notebook** | http://localhost:8888 | Aucun (désactivé) |
| **Spark UI** | http://localhost:4040 | - |
| **MinIO Console** | http://localhost:9001 | Voir fichier .env |
| **Iceberg REST API** | http://localhost:8181 | - |
| **ChromaDB** | http://localhost:8010 | - |
| **TimescaleDB** | localhost:5433 | Voir fichier .env |

## Technologies Utilisées

### **Apache Iceberg**
- Format de table ouvert pour lacs de données massifs
- Support ACID complet
- Time travel et versioning des données
- Évolution de schéma sans interruption
- Optimisation automatique des fichiers

### **Apache Spark**
- Moteur de traitement distribué
- Support SQL, Python, Scala
- Intégration native avec Iceberg
- Traitement batch et streaming

### **dbt (Data Build Tool)**
- Transformations SQL modulaires
- Tests de qualité de données
- Documentation automatique
- Gestion de versions avec Git
- Lignage des données

### **MinIO**
- Stockage objet compatible S3
- Haute disponibilité
- Scalabilité horizontale
- Chiffrement et sécurité

## Fichiers de Configuration

### **docker-compose.yml**
Configure tous les services et leurs interconnexions.

### **spark-defaults.conf**
Configuration Spark pour Iceberg:
```properties
spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.spark_catalog.type=rest
spark.sql.catalog.spark_catalog.uri=http://rest:8181
```

### **dbt_project/dbt_project.yml**
Configuration du projet dbt avec paramètres Iceberg.

### **dbt_project/profiles.yml**
Profils de connexion dbt vers Spark Thrift Server.

## Variables d'Environnement (.env)

```env
# MinIO
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# PostgreSQL/TimescaleDB
POSTGRES_DB=datamart
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

## Prochaines Étapes

Consultez les guides suivants:
1. [⚡ Guide de Démarrage Rapide](./QUICKSTART_FR.md)
2. [🔄 Guide de Transformation Bronze → Silver → Gold](./TRANSFORMATION_GUIDE_FR.md)
3. [🔗 Guide d'Intégration Airbyte-MinIO](./AIRBYTE_MINIO_INTEGRATION.md)
4. [📦 Guide de Structure MinIO](./MINIO_STRUCTURE_GUIDE.md)
5. [✅ Rapport de Vérification du Système](./VERIFICATION_REPORT.md)
6. [📋 Informations de Version](./VERSION_INFO.md)
7. [📝 Changelog](./CHANGELOG.md)

## Support et Ressources

- Documentation Apache Iceberg: https://iceberg.apache.org/
- Documentation dbt: https://docs.getdbt.com/
- Documentation Apache Spark: https://spark.apache.org/docs/latest/
- Documentation MinIO: https://min.io/docs/
