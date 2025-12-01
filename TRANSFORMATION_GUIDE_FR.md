# Guide de Transformation des Données: Bronze → Silver → Gold

Ce guide détaille comment transformer les données à travers les trois couches du Data Lakehouse.

## Table des Matières

1. [Principes de Transformation](#principes-de-transformation)
2. [Bronze → Silver avec dbt](#bronze--silver-avec-dbt)
3. [Silver → Gold avec dbt](#silver--gold-avec-dbt)
4. [Bronze → Silver → Gold avec Spark/Jupyter](#avec-spark-et-jupyter)
5. [Bonnes Pratiques](#bonnes-pratiques)

---

## Principes de Transformation

### Architecture Médaillon

```
BRONZE (Raw)          SILVER (Clean)          GOLD (Analytics)
────────────          ──────────────          ────────────────
• Données brutes      • Données nettoyées     • Données agrégées
• Pas de validation   • Validation stricte    • Enrichissement
• Format source       • Standardisation       • Métriques métier
• Append-only         • Dédoublonnage         • Prêt pour BI
```

### Règles de Transformation

**Bronze → Silver**:
- ✅ Nettoyer les valeurs nulles
- ✅ Standardiser les formats (dates, emails, etc.)
- ✅ Valider les types de données
- ✅ Ajouter métadonnées de traçabilité
- ❌ PAS de jointures
- ❌ PAS d'agrégations

**Silver → Gold**:
- ✅ Jointures entre tables
- ✅ Agrégations et calculs
- ✅ Métriques métier
- ✅ Dénormalisation pour performance
- ✅ Tables de faits et dimensions

---

## Bronze → Silver avec dbt

### Exemple 1: Nettoyage des Événements

**Fichier**: `dbt_project/models/staging/stg_events.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_silver'
  )
}}

-- Transformation Bronze → Silver pour les événements
-- Objectif: Nettoyer et valider les données brutes

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_events') }}
),

cleaned AS (
    SELECT
        -- Identifiants
        event_id,
        event_type,
        user_id,
        
        -- Nettoyage du timestamp
        CAST(event_timestamp AS TIMESTAMP) as event_timestamp,
        
        -- Nettoyage et standardisation des données
        TRIM(event_data) as event_data,
        
        -- Métadonnées de traçabilité
        current_timestamp() as dbt_loaded_at,
        'bronze.raw_events' as source_table
        
    FROM source
    
    -- Validation: Supprimer les enregistrements invalides
    WHERE 
        event_id IS NOT NULL
        AND event_type IS NOT NULL
        AND user_id IS NOT NULL
        AND event_timestamp IS NOT NULL
)

SELECT * FROM cleaned
```

**Exécution**:
```powershell
docker exec dbt dbt run --select stg_events
```

### Exemple 2: Nettoyage des Utilisateurs

**Fichier**: `dbt_project/models/staging/stg_users.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_silver'
  )
}}

-- Transformation Bronze → Silver pour les utilisateurs
-- Objectif: Nettoyer, valider et standardiser

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_users') }}
),

cleaned AS (
    SELECT
        -- Identifiant unique
        user_id,
        
        -- Nettoyage du nom
        TRIM(UPPER(SUBSTRING(user_name, 1, 1)) || LOWER(SUBSTRING(user_name, 2))) as user_name,
        
        -- Standardisation de l'email
        LOWER(TRIM(email)) as user_email,
        
        -- Validation du format email
        CASE 
            WHEN email LIKE '%@%.%' THEN LOWER(TRIM(email))
            ELSE NULL 
        END as user_email_validated,
        
        -- Dates
        CAST(created_at AS TIMESTAMP) as user_created_at,
        
        -- Calcul de l'ancienneté (en jours)
        DATEDIFF(current_date(), CAST(created_at AS DATE)) as user_age_days,
        
        -- Métadonnées
        current_timestamp() as dbt_loaded_at,
        'bronze.raw_users' as source_table
        
    FROM source
    
    -- Validation
    WHERE 
        user_id IS NOT NULL
        AND user_name IS NOT NULL
        AND created_at IS NOT NULL
)

SELECT * FROM cleaned
```

### Exemple 3: Dédoublonnage des Données

**Fichier**: `dbt_project/models/staging/stg_events_dedup.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_silver'
  )
}}

-- Dédoublonnage des événements
-- Prend la dernière version en cas de doublon

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_events') }}
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY event_id, user_id 
            ORDER BY event_timestamp DESC
        ) as rn
    FROM source
),

deduped AS (
    SELECT
        event_id,
        event_type,
        user_id,
        event_timestamp,
        event_data,
        current_timestamp() as dbt_loaded_at
    FROM ranked
    WHERE rn = 1
)

SELECT * FROM deduped
```

---

## Silver → Gold avec dbt

### Exemple 1: Table de Faits - Événements Enrichis

**Fichier**: `dbt_project/models/marts/fct_events_enriched.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_gold'
  )
}}

-- Table de faits: Événements enrichis avec informations utilisateur
-- Objectif: Jointure et enrichissement pour l'analyse

WITH events AS (
    SELECT * FROM {{ ref('stg_events') }}
),

users AS (
    SELECT * FROM {{ ref('stg_users') }}
),

enriched AS (
    SELECT
        -- Dimensions événement
        e.event_id,
        e.event_type,
        e.event_timestamp,
        e.event_data,
        
        -- Dimensions utilisateur (enrichissement)
        e.user_id,
        u.user_name,
        u.user_email,
        u.user_created_at,
        u.user_age_days,
        
        -- Métriques calculées
        CASE 
            WHEN e.event_type = 'login' THEN 1 
            ELSE 0 
        END as is_login,
        
        CASE 
            WHEN e.event_type = 'logout' THEN 1 
            ELSE 0 
        END as is_logout,
        
        -- Calcul de la durée depuis la création du compte
        DATEDIFF(e.event_timestamp, u.user_created_at) as days_since_registration,
        
        -- Métadonnées
        e.dbt_loaded_at
        
    FROM events e
    LEFT JOIN users u ON e.user_id = u.user_id
)

SELECT * FROM enriched
```

### Exemple 2: Table Agrégée - Statistiques Utilisateur

**Fichier**: `dbt_project/models/marts/dim_user_stats.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_gold'
  )
}}

-- Dimension: Statistiques par utilisateur
-- Objectif: Agréger les métriques par utilisateur

WITH events AS (
    SELECT * FROM {{ ref('fct_events_enriched') }}
),

user_stats AS (
    SELECT
        -- Dimensions
        user_id,
        user_name,
        user_email,
        user_created_at,
        
        -- Métriques d'activité
        COUNT(*) as total_events,
        COUNT(DISTINCT event_type) as unique_event_types,
        
        -- Métriques par type d'événement
        SUM(is_login) as total_logins,
        SUM(is_logout) as total_logouts,
        
        -- Métriques temporelles
        MIN(event_timestamp) as first_event_date,
        MAX(event_timestamp) as last_event_date,
        DATEDIFF(MAX(event_timestamp), MIN(event_timestamp)) as activity_period_days,
        
        -- Taux d'engagement
        COUNT(*) / NULLIF(DATEDIFF(CURRENT_DATE(), user_created_at), 0) as avg_events_per_day,
        
        -- Métadonnées
        current_timestamp() as dbt_loaded_at
        
    FROM events
    GROUP BY 
        user_id,
        user_name,
        user_email,
        user_created_at
)

SELECT * FROM user_stats
```

### Exemple 3: Table Agrégée - Statistiques Quotidiennes

**Fichier**: `dbt_project/models/marts/fct_daily_activity.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_gold'
  )
}}

-- Fait: Activité quotidienne
-- Objectif: Métriques agrégées par jour

WITH events AS (
    SELECT * FROM {{ ref('fct_events_enriched') }}
),

daily_stats AS (
    SELECT
        -- Dimensions temporelles
        CAST(event_timestamp AS DATE) as activity_date,
        EXTRACT(YEAR FROM event_timestamp) as activity_year,
        EXTRACT(MONTH FROM event_timestamp) as activity_month,
        EXTRACT(DAY FROM event_timestamp) as activity_day,
        DAYOFWEEK(event_timestamp) as day_of_week,
        
        -- Métriques
        COUNT(*) as total_events,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT event_type) as unique_event_types,
        
        -- Métriques par type
        SUM(is_login) as total_logins,
        SUM(is_logout) as total_logouts,
        
        -- Métriques de qualité
        COUNT(*) / COUNT(DISTINCT user_id) as avg_events_per_user,
        
        -- Métadonnées
        current_timestamp() as dbt_loaded_at
        
    FROM events
    GROUP BY 
        activity_date,
        activity_year,
        activity_month,
        activity_day,
        day_of_week
)

SELECT * FROM daily_stats
ORDER BY activity_date DESC
```

**Exécution des modèles Gold**:
```powershell
# Exécuter tous les modèles marts
docker exec dbt dbt run --select marts

# Exécuter un modèle spécifique
docker exec dbt dbt run --select fct_daily_activity
```

---

## Avec Spark et Jupyter

### Configuration Initiale dans Jupyter

Ouvrez Jupyter: http://localhost:8888

**Créer un nouveau notebook et configurer Spark**:

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Créer une session Spark avec Iceberg
spark = SparkSession.builder \
    .appName("Data Transformation") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.spark_catalog.type", "rest") \
    .config("spark.sql.catalog.spark_catalog.uri", "http://rest:8181") \
    .getOrCreate()

print("Spark session créée avec succès!")
spark.sql("SHOW NAMESPACES").show()
```

### Bronze → Silver avec PySpark

```python
# ============================================
# TRANSFORMATION BRONZE → SILVER avec PySpark
# ============================================

# 1. Lire les données brutes depuis Bronze
print("📖 Lecture des données Bronze...")
df_raw_events = spark.table("bronze.raw_events")
df_raw_users = spark.table("bronze.raw_users")

print(f"Événements bruts: {df_raw_events.count()} lignes")
print(f"Utilisateurs bruts: {df_raw_users.count()} lignes")

# 2. Nettoyer les événements
print("\n🧹 Nettoyage des événements...")

df_events_clean = df_raw_events \
    .filter(col("event_id").isNotNull()) \
    .filter(col("event_type").isNotNull()) \
    .filter(col("user_id").isNotNull()) \
    .withColumn("event_timestamp", col("event_timestamp").cast("timestamp")) \
    .withColumn("event_data", trim(col("event_data"))) \
    .withColumn("dbt_loaded_at", current_timestamp()) \
    .withColumn("source_table", lit("bronze.raw_events"))

# Afficher un aperçu
df_events_clean.show(5, truncate=False)

# 3. Dédoublonner les événements
print("\n🔄 Dédoublonnage...")

from pyspark.sql.window import Window

window_spec = Window.partitionBy("event_id", "user_id").orderBy(col("event_timestamp").desc())

df_events_dedup = df_events_clean \
    .withColumn("rn", row_number().over(window_spec)) \
    .filter(col("rn") == 1) \
    .drop("rn")

print(f"Après dédoublonnage: {df_events_dedup.count()} lignes")

# 4. Nettoyer les utilisateurs
print("\n🧹 Nettoyage des utilisateurs...")

df_users_clean = df_raw_users \
    .filter(col("user_id").isNotNull()) \
    .filter(col("user_name").isNotNull()) \
    .withColumn("user_name", trim(col("user_name"))) \
    .withColumn("user_email", lower(trim(col("email")))) \
    .withColumn("user_created_at", col("created_at").cast("timestamp")) \
    .withColumn("user_age_days", datediff(current_date(), col("created_at"))) \
    .withColumn("dbt_loaded_at", current_timestamp()) \
    .select(
        "user_id",
        "user_name",
        "user_email",
        "user_created_at",
        "user_age_days",
        "dbt_loaded_at"
    )

df_users_clean.show(5, truncate=False)

# 5. Écrire dans Silver
print("\n💾 Écriture dans Silver...")

# Créer le namespace Silver si nécessaire
spark.sql("CREATE NAMESPACE IF NOT EXISTS silver")

# Écrire les événements nettoyés
df_events_dedup.writeTo("silver.stg_events") \
    .using("iceberg") \
    .createOrReplace()

print("✅ silver.stg_events créé!")

# Écrire les utilisateurs nettoyés
df_users_clean.writeTo("silver.stg_users") \
    .using("iceberg") \
    .createOrReplace()

print("✅ silver.stg_users créé!")

# 6. Vérification
print("\n🔍 Vérification des tables Silver...")
spark.sql("SHOW TABLES IN silver").show()

print("\nContenu de silver.stg_events:")
spark.table("silver.stg_events").show(5)

print("\nContenu de silver.stg_users:")
spark.table("silver.stg_users").show(5)
```

### Silver → Gold avec PySpark

```python
# ============================================
# TRANSFORMATION SILVER → GOLD avec PySpark
# ============================================

# 1. Lire les données Silver
print("📖 Lecture des données Silver...")
df_events = spark.table("silver.stg_events")
df_users = spark.table("silver.stg_users")

# 2. Enrichissement: Joindre événements et utilisateurs
print("\n🔗 Jointure et enrichissement...")

df_enriched = df_events.alias("e") \
    .join(
        df_users.alias("u"),
        col("e.user_id") == col("u.user_id"),
        "left"
    ) \
    .select(
        # Colonnes événement
        col("e.event_id"),
        col("e.event_type"),
        col("e.event_timestamp"),
        col("e.event_data"),
        
        # Colonnes utilisateur
        col("e.user_id"),
        col("u.user_name"),
        col("u.user_email"),
        col("u.user_created_at"),
        col("u.user_age_days"),
        
        # Métriques calculées
        when(col("e.event_type") == "login", 1).otherwise(0).alias("is_login"),
        when(col("e.event_type") == "logout", 1).otherwise(0).alias("is_logout"),
        datediff(col("e.event_timestamp"), col("u.user_created_at")).alias("days_since_registration"),
        
        # Métadonnées
        col("e.dbt_loaded_at")
    )

df_enriched.show(10, truncate=False)

# 3. Agrégation: Statistiques par utilisateur
print("\n📊 Calcul des statistiques par utilisateur...")

df_user_stats = df_enriched.groupBy(
    "user_id",
    "user_name",
    "user_email",
    "user_created_at"
).agg(
    count("*").alias("total_events"),
    countDistinct("event_type").alias("unique_event_types"),
    sum("is_login").alias("total_logins"),
    sum("is_logout").alias("total_logouts"),
    min("event_timestamp").alias("first_event_date"),
    max("event_timestamp").alias("last_event_date"),
    (datediff(max("event_timestamp"), min("event_timestamp"))).alias("activity_period_days")
).withColumn(
    "avg_events_per_day",
    col("total_events") / when(col("activity_period_days") > 0, col("activity_period_days")).otherwise(1)
).withColumn(
    "dbt_loaded_at",
    current_timestamp()
)

df_user_stats.show(truncate=False)

# 4. Agrégation: Activité quotidienne
print("\n📅 Calcul de l'activité quotidienne...")

df_daily_activity = df_enriched \
    .withColumn("activity_date", to_date(col("event_timestamp"))) \
    .withColumn("activity_year", year(col("event_timestamp"))) \
    .withColumn("activity_month", month(col("event_timestamp"))) \
    .withColumn("activity_day", dayofmonth(col("event_timestamp"))) \
    .withColumn("day_of_week", dayofweek(col("event_timestamp"))) \
    .groupBy(
        "activity_date",
        "activity_year",
        "activity_month",
        "activity_day",
        "day_of_week"
    ).agg(
        count("*").alias("total_events"),
        countDistinct("user_id").alias("unique_users"),
        countDistinct("event_type").alias("unique_event_types"),
        sum("is_login").alias("total_logins"),
        sum("is_logout").alias("total_logouts")
    ).withColumn(
        "avg_events_per_user",
        col("total_events") / col("unique_users")
    ).withColumn(
        "dbt_loaded_at",
        current_timestamp()
    ).orderBy(col("activity_date").desc())

df_daily_activity.show(truncate=False)

# 5. Écrire dans Gold
print("\n💾 Écriture dans Gold...")

# Créer le namespace Gold
spark.sql("CREATE NAMESPACE IF NOT EXISTS gold")

# Écrire la table enrichie
df_enriched.writeTo("gold.fct_events_enriched") \
    .using("iceberg") \
    .createOrReplace()

print("✅ gold.fct_events_enriched créé!")

# Écrire les statistiques utilisateur
df_user_stats.writeTo("gold.dim_user_stats") \
    .using("iceberg") \
    .createOrReplace()

print("✅ gold.dim_user_stats créé!")

# Écrire l'activité quotidienne
df_daily_activity.writeTo("gold.fct_daily_activity") \
    .using("iceberg") \
    .createOrReplace()

print("✅ gold.fct_daily_activity créé!")

# 6. Vérification finale
print("\n🔍 Vérification des tables Gold...")
spark.sql("SHOW TABLES IN gold").show()

print("\n📊 Résumé des données Gold:")
print(f"Événements enrichis: {spark.table('gold.fct_events_enriched').count()} lignes")
print(f"Statistiques utilisateur: {spark.table('gold.dim_user_stats').count()} lignes")
print(f"Activité quotidienne: {spark.table('gold.fct_daily_activity').count()} lignes")
```

---

## Bonnes Pratiques

### 1. Nommage des Tables

```
Bronze:  raw_<nom>              ex: raw_events, raw_users
Silver:  stg_<nom>              ex: stg_events, stg_users
Gold:    fct_<nom> / dim_<nom>  ex: fct_events_enriched, dim_user_stats
```

### 2. Traçabilité

Toujours ajouter:
- `dbt_loaded_at`: Timestamp de chargement
- `source_table`: Table source
- `processing_date`: Date de traitement (pour partitionnement)

### 3. Validation des Données

```sql
-- Tests dbt dans schema.yml
tests:
  - not_null
  - unique
  - relationships
  - accepted_values
```

### 4. Partitionnement Iceberg

Pour les grandes tables:

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    partition_by=['year(event_timestamp)', 'month(event_timestamp)']
  )
}}
```

### 5. Incrémental avec dbt

Pour mise à jour incrémentale:

```sql
{{
  config(
    materialized='incremental',
    file_format='iceberg',
    unique_key='event_id'
  )
}}

SELECT *
FROM {{ source('bronze', 'raw_events') }}

{% if is_incremental() %}
  WHERE event_timestamp > (SELECT MAX(event_timestamp) FROM {{ this }})
{% endif %}
```

### 6. Documentation

Documenter chaque modèle dans `schema.yml`:

```yaml
models:
  - name: stg_events
    description: Événements nettoyés depuis bronze
    columns:
      - name: event_id
        description: Identifiant unique de l'événement
        tests:
          - not_null
          - unique
```

---

## Commandes Utiles

```powershell
# Exécuter toute la chaîne
docker exec dbt dbt run

# Exécuter Bronze → Silver uniquement
docker exec dbt dbt run --select staging

# Exécuter Silver → Gold uniquement
docker exec dbt dbt run --select marts

# Tester la qualité des données
docker exec dbt dbt test

# Vérifier les tables
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW NAMESPACES;"
```

## Conclusion

Ce guide vous a montré comment:
- ✅ Nettoyer les données (Bronze → Silver)
- ✅ Enrichir et agréger (Silver → Gold)
- ✅ Utiliser dbt et Spark/Jupyter
- ✅ Suivre les bonnes pratiques

**Prochaine étape**: Consultez la [documentation officielle dbt](https://docs.getdbt.com/) pour des transformations plus complexes!
