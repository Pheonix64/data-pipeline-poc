# Organisation des Buckets MinIO - Best Practices

## Structure Recommandée des Buckets

Voici comment organiser vos données dans MinIO pour une meilleure gestion:

---

## Bucket: `bronze/` (Données Brutes)

### Structure Suggérée

```
bronze/
├── airbyte/                    # Données depuis Airbyte (créé auto)
│   ├── postgres/               # Par source de données
│   │   ├── public/             # Par schéma
│   │   │   ├── users/          # Par table
│   │   │   │   └── 2025_10_21_*.parquet
│   │   │   └── orders/
│   │   └── sales/
│   ├── salesforce/
│   │   ├── accounts/
│   │   └── contacts/
│   └── api_rest/
│       └── events/
│
├── manual/                     # Chargements manuels (à créer si besoin)
│   ├── csv_imports/
│   └── excel_imports/
│
└── streaming/                  # Données streaming (à créer si besoin)
    └── kafka_topics/
```

### 🤖 Création Automatique

**Airbyte créera automatiquement**:
- Le dossier `airbyte/` lors de la première synchro
- Les sous-dossiers pour chaque source/table

**Vous n'avez RIEN à créer manuellement!**

---

## Bucket: `silver/` (Données Nettoyées)

### Structure Suggérée

```
silver/
├── staging/                    # Tables staging (stg_*)
│   ├── postgres/
│   │   ├── stg_users/
│   │   └── stg_orders/
│   └── salesforce/
│       └── stg_accounts/
│
└── cleaned/                    # Données nettoyées sans préfixe stg_
    ├── users_clean/
    └── orders_clean/
```

### 🤖 Création Automatique

**dbt/Spark créera automatiquement** ces dossiers lors de l'exécution des modèles.

---

## Bucket: `gold/` (Données Analytiques)

### Structure Suggérée

```
gold/
├── facts/                      # Tables de faits (fct_*)
│   ├── fct_sales/
│   ├── fct_customer_activity/
│   └── fct_revenue/
│
├── dimensions/                 # Tables de dimensions (dim_*)
│   ├── dim_customers/
│   ├── dim_products/
│   └── dim_time/
│
├── metrics/                    # Métriques agrégées
│   ├── daily_kpis/
│   └── monthly_summary/
│
└── reports/                    # Données pour rapports BI
    ├── executive_dashboard/
    └── sales_reports/
```

### 🤖 Création Automatique

**dbt/Spark créera automatiquement** lors de l'exécution des modèles marts.

---

## Bucket: `lakehouse/` (Métadonnées Iceberg)

### Structure (Gérée par Iceberg)

```
lakehouse/
├── bronze/                     # Namespace bronze
│   ├── raw_events/
│   │   ├── metadata/           # Métadonnées Iceberg
│   │   │   ├── v1.metadata.json
│   │   │   └── snap-*.avro
│   │   └── data/               # Fichiers de données
│   │       └── *.parquet
│   └── raw_users/
│       ├── metadata/
│       └── data/
│
├── default_silver/             # Namespace silver
│   ├── stg_events/
│   └── stg_users/
│
└── default_gold/               # Namespace gold
    └── fct_events_enriched/
```

### ⚠️ NE PAS MODIFIER MANUELLEMENT

Iceberg gère cette structure automatiquement. **Ne touchez pas à ce bucket!**

---

## Configuration pour Airbyte

### Paramètres Recommandés

Lors de la configuration de la destination S3 dans Airbyte:

```yaml
S3 Bucket Path: airbyte/         # ← Préfixe pour toutes les données Airbyte

S3 Path Format: ${NAMESPACE}/${STREAM_NAME}/${YEAR}_${MONTH}_${DAY}_${EPOCH}_
```

**Résultat automatique**:
```
bronze/airbyte/public/users/2025_10_21_1729508400_0.parquet
bronze/airbyte/sales/orders/2025_10_21_1729508400_0.parquet
```

---

## Dois-je Créer les Dossiers Manuellement?

### ❌ Non, Sauf Cas Spécifiques

**Créés automatiquement par**:
- ✅ Airbyte → `bronze/airbyte/*`
- ✅ Spark/Iceberg → `lakehouse/*` + toutes les tables
- ✅ dbt → Selon vos modèles

**À créer manuellement SEULEMENT si**:
- Vous voulez une structure personnalisée avant de commencer
- Vous chargez des fichiers manuellement (CSV, Excel, etc.)
- Vous avez des besoins d'organisation spécifiques

---

## Comment Créer des Dossiers Manuellement (Si Besoin)

### Via MinIO Console (Interface Web)

1. Accédez à http://localhost:9001
2. Connectez-vous (`admin` / `SuperSecret123`)
3. Cliquez sur le bucket (`bronze`, `silver`, ou `gold`)
4. Cliquez sur "Create new path" ou "Upload"
5. Les dossiers seront créés automatiquement avec le premier fichier

### Via MinIO CLI (mc)

```powershell
# Se connecter au conteneur
docker exec -it minio bash

# Créer un alias (si pas déjà fait)
mc alias set local http://localhost:9000 admin SuperSecret123

# Créer un "dossier" (en créant un fichier vide)
echo "" | mc pipe local/bronze/manual/imports/.keep

# Ou copier un fichier pour créer le chemin
mc cp /tmp/example.csv local/bronze/manual/imports/example.csv
```

### Via Script (pour automatisation)

Créez un script `setup-minio-paths.sh`:

```bash
#!/bin/bash

# Créer les chemins dans Bronze
mc pipe local/bronze/airbyte/.keep < /dev/null
mc pipe local/bronze/manual/.keep < /dev/null
mc pipe local/bronze/streaming/.keep < /dev/null

# Créer les chemins dans Silver
mc pipe local/silver/staging/.keep < /dev/null
mc pipe local/silver/cleaned/.keep < /dev/null

# Créer les chemins dans Gold
mc pipe local/gold/facts/.keep < /dev/null
mc pipe local/gold/dimensions/.keep < /dev/null
mc pipe local/gold/metrics/.keep < /dev/null
mc pipe local/gold/reports/.keep < /dev/null

echo "✅ Structure créée!"
```

Exécuter:
```powershell
docker exec -i minio bash < setup-minio-paths.sh
```

---

## Vérifier la Structure Actuelle

### Via MinIO Console
http://localhost:9001 → Naviguer dans les buckets

### Via MinIO CLI

```powershell
# Lister tous les buckets
docker exec minio mc ls local/

# Lister le contenu du bucket bronze
docker exec minio mc ls local/bronze/

# Lister récursivement
docker exec minio mc ls --recursive local/bronze/
```

### Via Spark/Beeline

```powershell
# Lister les fichiers S3 depuis Spark
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
  -- Cela ne liste que les tables Iceberg, pas les fichiers bruts
  SHOW TABLES IN bronze;
"
```

---

## Exemple: Flux Complet avec Structure Automatique

### 1. Airbyte Synchronise des Données

**Configuration Airbyte**:
- Bucket: `bronze`
- Path: `airbyte/`

**Résultat automatique**:
```
bronze/
└── airbyte/                    # ← Créé par Airbyte
    └── public/                 # ← Créé par Airbyte
        └── users/              # ← Créé par Airbyte
            └── 2025_10_21_*.parquet
```

### 2. Créer une Table Iceberg sur les Données Airbyte

```sql
-- Dans Spark/Jupyter
CREATE TABLE bronze.airbyte_users
USING iceberg
LOCATION 's3a://bronze/airbyte/public/users/';
```

**Résultat dans MinIO**:
```
lakehouse/
└── bronze/                     # ← Créé par Iceberg
    └── airbyte_users/          # ← Créé par Iceberg
        ├── metadata/           # ← Géré par Iceberg
        └── data/               # ← Géré par Iceberg (liens vers bronze/airbyte/)
```

### 3. Transformer avec dbt (Bronze → Silver)

```sql
-- dbt_project/models/staging/stg_users.sql
{{ config(
    materialized='table',
    file_format='iceberg',
    schema='default_silver'
) }}

SELECT * FROM {{ ref('airbyte_users') }}
WHERE user_id IS NOT NULL
```

**Résultat après `dbt run`**:
```
lakehouse/
└── default_default_silver/     # ← Créé par dbt
    └── stg_users/              # ← Créé par dbt
        ├── metadata/
        └── data/
```

---

## Recommandations Finales

### ✅ À Faire

1. **Laisser les outils créer automatiquement** la structure
2. **Documenter** votre convention de nommage
3. **Utiliser des préfixes** cohérents:
   - `airbyte/` pour données Airbyte
   - `manual/` pour chargements manuels
   - `stg_` pour staging
   - `fct_` pour facts
   - `dim_` pour dimensions

### ❌ À Éviter

1. **Ne pas créer** de dossiers vides "au cas où"
2. **Ne pas modifier** le bucket `lakehouse/` manuellement
3. **Ne pas mélanger** différentes sources de données au même niveau

### 📋 Checklist de Démarrage

- [ ] Vérifier que les 4 buckets existent (`bronze`, `silver`, `gold`, `lakehouse`)
- [ ] Configurer Airbyte avec le chemin `airbyte/`
- [ ] Lancer la première synchronisation Airbyte
- [ ] Vérifier dans MinIO Console que les données sont arrivées
- [ ] Créer une table Iceberg sur les données Airbyte
- [ ] Transformer avec dbt
- [ ] Documenter votre structure dans un README

---

## En Résumé

### Question: "Dois-je créer des paths sous bronze, silver, etc.?"

**Réponse: NON! 🎉**

- Les outils (Airbyte, Spark, dbt) créent automatiquement les chemins
- Vous n'avez qu'à configurer les préfixes dans Airbyte
- La structure se construit au fur et à mesure de vos pipelines

**Exception**: Uniquement si vous chargez des fichiers manuellement avant d'avoir des pipelines automatiques.

---

## Commande Rapide pour Vérifier

```powershell
# Voir la structure actuelle
docker exec minio mc tree local/bronze/
docker exec minio mc tree local/silver/
docker exec minio mc tree local/gold/

# Si la commande tree n'existe pas:
docker exec minio mc ls --recursive local/bronze/
```

Profitez de l'automatisation! 🚀
