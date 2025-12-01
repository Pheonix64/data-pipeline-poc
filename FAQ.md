# ❓ FAQ - Data Pipeline POC BCEAO

**Questions Fr\u00e9quentes** sur le Data Pipeline POC BCEAO pour l'analyse des indicateurs \u00e9conomiques de l'UEMOA

**Derni\u00e8re mise \u00e0 jour** : 1er d\u00e9cembre 2025

---

## 📋 Table des Mati\u00e8res

- [G\u00e9n\u00e9ral](#-g\u00e9n\u00e9ral)
- [Installation et Configuration](#-installation-et-configuration)
- [Architecture et Donn\u00e9es](#-architecture-et-donn\u00e9es)
- [Utilisation Quotidienne](#-utilisation-quotidienne)
- [UEMOA Sp\u00e9cifique](#-uemoa-sp\u00e9cifique)
- [Performance et Optimisation](#-performance-et-optimisation)
- [S\u00e9curit\u00e9 et Production](#-s\u00e9curit\u00e9-et-production)

---

## 📌 G\u00e9n\u00e9ral

### Q : C'est quoi ce projet exactement ?

**R** : Un **Data Lakehouse moderne** pour analyser les indicateurs \u00e9conomiques de l'UEMOA. Il utilise :
- **Apache Iceberg** : Format de table avec ACID transactions
- **Apache Spark** : Moteur de traitement distribu\u00e9
- **dbt** : Transformations SQL
- **MinIO** : Stockage S3-compatible
- **TimescaleDB** : Base de donn\u00e9es time-series

→ [README_FR.md](./README_FR.md) pour plus de d\u00e9tails

---

### Q : Quelle est la diff\u00e9rence entre Bronze, Silver et Gold ?

**R** : C'est l'**architecture M\u00e9daillon** :
- 🥉 **Bronze** : Donn\u00e9es brutes, non modifi\u00e9es (raw data from Airbyte)
- 🥈 **Silver** : Donn\u00e9es nettoy\u00e9es, valid\u00e9es, standardis\u00e9es
- 🥇 **Gold** : Donn\u00e9es analytics-ready (marts, KPIs, dashboards)

→ [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)

---

### Q : Combien de temps prend l'installation ?

**R** : Environ **15-30 minutes** :
- 5 min : T\u00e9l\u00e9chargement des images Docker
- 5 min : D\u00e9marrage des services
- 5-10 min : Initialisation du lakehouse
- 5 min : Premier test avec dbt run

→ [QUICKSTART_FR.md](./QUICKSTART_FR.md)

---

### Q : Quels sont les pr\u00e9requis syst\u00e8me ?

**R** :
- **OS** : Windows 10/11, macOS 12+, ou Ubuntu 20.04+
- **Docker Desktop** : version 20.10+
- **RAM** : minimum 8GB (recommand\u00e9 16GB)
- **Disque** : minimum 50GB libre
- **CPU** : 4 cores minimum

→ [VERSION_INFO.md](./VERSION_INFO.md)

---

## 🔧 Installation et Configuration

### Q : Comment installer le projet ?

**R** : En 4 \u00e9tapes simples :
```powershell
# 1. Cr\u00e9er le fichier .env avec credentials
# 2. T\u00e9l\u00e9charger les JARs AWS dans ./jars/
# 3. docker-compose up -d
# 4. docker exec dbt bash -c \"cd /usr/app/dbt && dbt run\"
```

→ [QUICKSTART_FR.md](./QUICKSTART_FR.md) pour le guide d\u00e9taill\u00e9

---

### Q : Pourquoi le port 5432 vs 5433 pour TimescaleDB ?

**R** : Deux ports diff\u00e9rents pour deux usages :
- **Port 5432** : Communication INTERNE entre conteneurs Docker (Spark → TimescaleDB)
- **Port 5433** : Acc\u00e8s EXTERNE depuis l'h\u00f4te Windows (psql, DBeaver)

**Exemple** :
```python
# Depuis un conteneur (PySpark)
jdbc_url = \"jdbc:postgresql://timescaledb:5432/...\"

# Depuis Windows
psql -h localhost -p 5433 -U postgres
```

→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

### Q : Comment changer les credentials MinIO ?

**R** : Modifier le fichier `.env` :
```env
MINIO_ROOT_USER=votre_username
MINIO_ROOT_PASSWORD=votre_password
```

Puis red\u00e9marrer :
```powershell
docker-compose down
docker-compose up -d
```

---

### Q : Les conteneurs ne d\u00e9marrent pas, que faire ?

**R** : V\u00e9rifier dans l'ordre :
1. Docker Desktop est d\u00e9marr\u00e9 : `docker info`
2. Ports libres : `netstat -ano | findstr :9001`
3. M\u00e9moire suffisante : Docker Settings → Resources
4. Logs : `docker-compose logs`

→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#1%EF%B8%8F⃣-probl\u00e8mes-docker-et-services)

---

## 🏗️ Architecture et Donn\u00e9es

### Q : C'est quoi Apache Iceberg ?

**R** : Un **format de table open-source** pour data lakes avec :
- ✅ Transactions ACID (comme une base de donn\u00e9es)
- ✅ Time travel (requ\u00eater des versions historiques)
- ✅ \u00c9volution de sch\u00e9ma sans downtime
- ✅ Optimisation automatique des fichiers
- ✅ Partitioning cach\u00e9 (pas besoin de pr\u00e9dicats de partition dans les requ\u00eates)

→ [ARCHITECTURE.md](./ARCHITECTURE.md)

---

### Q : Pourquoi utiliser dbt au lieu de PySpark direct ?

**R** : dbt apporte :
- 📝 **SQL pur** : Plus simple que PySpark pour transformations
- 🧪 **Tests automatiques** : Qualit\u00e9 des donn\u00e9es garantie
- 📊 **Documentation auto** : `dbt docs generate`
- 🔄 **Lign\u00e9e des donn\u00e9es** : Visualisation du DAG
- 🔁 **Incr\u00e9mental** : Chargements optimis\u00e9s

→ [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)

---

### Q : O\u00f9 sont stock\u00e9es les donn\u00e9es physiquement ?

**R** : Dans MinIO (S3-compatible) :
```
minio_data/lakehouse/
  ├── bronze/             # Tables brutes
  │   └── indicateurs_economiques_uemoa/
  ├── default_silver/     # Tables nettoy\u00e9es
  └── default_gold/       # Tables analytics
```

Les **m\u00e9tadonn\u00e9es** Iceberg (snapshots, manifests) sont dans `lakehouse/*/metadata/`

→ [MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md)

---

### Q : Quelle est la diff\u00e9rence entre \"gold\" et \"default_gold\" ?

**R** : **`default_gold`** est le **namespace Iceberg r\u00e9el**.

Explication :
- Dans `dbt_project.yml`, on configure `schema: gold`
- dbt ajoute le pr\u00e9fixe \"default_\" → R\u00e9sultat = `default_gold`

**Toujours utiliser** :
```sql
SELECT * FROM default_gold.table_name  -- ✅ CORRECT
SELECT * FROM gold.table_name          -- ❌ INCORRECT
```

---

### Q : Comment voir toutes les tables disponibles ?

**R** :
```powershell
# Lister les namespaces
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SHOW NAMESPACES;\"

# Lister les tables d'un namespace
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SHOW TABLES IN default_gold;\"
```

→ [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

## 💼 Utilisation Quotidienne

### Q : Comment d\u00e9marrer/arr\u00eater le syst\u00e8me ?

**R** :
```powershell
# D\u00e9marrer
docker-compose up -d

# Arr\u00eater (conserve les donn\u00e9es)
docker-compose down

# Arr\u00eater ET supprimer donn\u00e9es (⚠️ DANGER)
docker-compose down -v
```

---

### Q : Comment ex\u00e9cuter les transformations dbt ?

**R** :
```powershell
# Toutes les transformations
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run\"

# Uniquement Silver
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select staging\"

# Uniquement Gold
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select gold\"

# Un mod\u00e8le sp\u00e9cifique
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select gold_mart_uemoa_monetary_dashboard\"
```

---

### Q : Comment requ\u00eater les donn\u00e9es ?

**R** : Trois options :

**Option 1 : Beeline (CLI)**
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SELECT * FROM default_gold.fct_events_enriched LIMIT 10;\"
```

**Option 2 : Jupyter Notebook** (http://localhost:8888)
```python
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
df = spark.sql(\"SELECT * FROM default_gold.fct_events_enriched\")
df.show()
```

**Option 3 : dbt** (avec jinja)
```sql
-- models/custom/my_analysis.sql
SELECT * FROM {{ ref('fct_events_enriched') }}
```

---

### Q : Comment ajouter une nouvelle transformation ?

**R** :
1. Cr\u00e9er un fichier SQL dans `dbt_project/models/gold/`
2. \u00c9crire la transformation :
```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

SELECT
    date,
    SUM(montant) as total
FROM {{ ref('dim_uemoa_indicators') }}
GROUP BY date
```
3. Ex\u00e9cuter : `docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select mon_modele\"`

→ [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)

---

### Q : Comment voir les logs d'un service ?

**R** :
```powershell
# Logs en temps r\u00e9el
docker-compose logs -f spark-iceberg

# Logs d'un conteneur sp\u00e9cifique
docker logs spark-iceberg

# Logs dbt
docker exec dbt cat /usr/app/dbt/logs/dbt.log
```

---

## 🏦 UEMOA Sp\u00e9cifique

### Q : Quelles sont les tables UEMOA disponibles ?

**R** : **5 marts Gold** :
1. `gold_kpi_uemoa_growth_yoy` - Croissance YoY
2. `gold_mart_uemoa_external_stability` - Stabilit\u00e9 externe
3. `gold_mart_uemoa_external_trade` - Commerce ext\u00e9rieur
4. `gold_mart_uemoa_monetary_dashboard` - Dashboard mon\u00e9taire
5. `gold_mart_uemoa_public_finance` - Finances publiques

→ [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md)

---

### Q : Comment cr\u00e9er la table Bronze UEMOA ?

**R** : Apr\u00e8s ingestion Airbyte (fichiers Parquet dans MinIO) :
```powershell
# Copier le script
docker cp create_uemoa_table.py spark-iceberg:/tmp/

# Ex\u00e9cuter
docker exec spark-iceberg bash -lc \"cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py\"
```

→ [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md#cr\u00e9ation-de-la-table-bronze)

---

### Q : Comment copier les datamarts UEMOA vers TimescaleDB ?

**R** :
```powershell
# 1. Installer le driver PostgreSQL JDBC
.\\setup_postgresql_driver.ps1

# 2. Ex\u00e9cuter la copie
.\\run_copy_uemoa.ps1
```

**R\u00e9sultat** : 5 tables copi\u00e9es dans TimescaleDB (`monetary_policy_dm`)

→ [COPY_UEMOA_TO_TIMESCALE.md](./COPY_UEMOA_TO_TIMESCALE.md)

---

### Q : Comment v\u00e9rifier les crit\u00e8res de convergence UEMOA ?

**R** : Requ\u00eates SQL pr\u00e9-\u00e9crites :
```sql
-- Crit\u00e8re 1 : Solde budg\u00e9taire ≥ -3%
SELECT date, solde_budgetaire_avec_dons_pct_pib,
  CASE WHEN solde_budgetaire_avec_dons_pct_pib >= -3 THEN '✓' ELSE '✗' END
FROM default_gold.gold_mart_uemoa_public_finance
ORDER BY date DESC LIMIT 10;

-- Crit\u00e8re 2 : Inflation ≤ 3%
-- Crit\u00e8re 3 : Dette/PIB ≤ 70%
```

→ [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md#-crit\u00e8res-de-convergence-uemoa)

---

## ⚡ Performance et Optimisation

### Q : Les transformations dbt sont lentes, comment acc\u00e9l\u00e9rer ?

**R** : Plusieurs techniques :

**1. Partitioning Iceberg**
```sql
{{
  config(
    partition_by=['year(date)']
  )
}}
```

**2. Incr\u00e9mental dbt**
```sql
{{
  config(
    materialized='incremental',
    unique_key='id'
  )
}}
```

**3. Augmenter la m\u00e9moire Spark**
```yaml
# docker-compose.yml
environment:
  - SPARK_DRIVER_MEMORY=8g
  - SPARK_EXECUTOR_MEMORY=8g
```

→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#7%EF%B8%8F⃣-probl\u00e8mes-de-performance)

---

### Q : Comment optimiser les fichiers Iceberg ?

**R** : Compaction p\u00e9riodique :
```sql
-- Regrouper les petits fichiers
CALL local.system.rewrite_data_files(
    table => 'bronze.indicateurs_economiques_uemoa',
    strategy => 'binpack',
    options => map('target-file-size-bytes','536870912')
);

-- Expirer les vieux snapshots
CALL local.system.expire_snapshots(
    table => 'bronze.indicateurs_economiques_uemoa',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 100
);
```

→ [ARCHITECTURE.md](./ARCHITECTURE.md#performance)

---

### Q : Combien de donn\u00e9es le syst\u00e8me peut-il g\u00e9rer ?

**R** : Scalabilit\u00e9 :
- **Dev/Test** : Jusqu'\u00e0 10-100 millions de lignes
- **Production** : Milliards de lignes (avec cluster Spark)
- **Scaling horizontal** : Ajouter des workers Spark

Le syst\u00e8me est con\u00e7u pour \u00e9voluer avec :
- Spark distribu\u00e9 (via Kubernetes ou YARN)
- MinIO multi-nodes
- Iceberg optimis\u00e9 pour big data

---

## 🔒 S\u00e9curit\u00e9 et Production

### Q : Le syst\u00e8me est-il s\u00e9curis\u00e9 pour la production ?

**R** : **Non, la configuration actuelle est pour DEV uniquement.**

**Manque pour production** :
- ❌ Credentials en clair dans .env
- ❌ Pas de HTTPS/TLS
- ❌ Pas d'authentification Spark
- ❌ Jupyter sans mot de passe
- ❌ Pas d'encryption at rest

**Recommandations production** : Voir documentation (à venir)

---

### Q : Comment sauvegarder les donn\u00e9es ?

**R** : Backup de 3 \u00e9l\u00e9ments :

**1. Donn\u00e9es MinIO**
```powershell
docker exec mc mc mirror --preserve bceao-data/lakehouse /backup/lakehouse
```

**2. M\u00e9tadonn\u00e9es Iceberg** (inclus dans MinIO backup)

**3. TimescaleDB**
```powershell
docker exec timescaledb pg_dump -U postgres monetary_policy_dm > backup.sql
```

→ Documentation backup compl\u00e8te (à venir)

---

### Q : Comment restaurer apr\u00e8s un crash ?

**R** :
```powershell
# 1. Restaurer MinIO
docker exec mc mc mirror /backup/lakehouse bceao-data/lakehouse

# 2. Restaurer TimescaleDB
docker exec -i timescaledb psql -U postgres monetary_policy_dm < backup.sql

# 3. Red\u00e9marrer les services
docker-compose restart
```

---

### Q : Comment monitorer le syst\u00e8me en production ?

**R** : \u00c0 impl\u00e9menter :
- 📊 **Prometheus** : M\u00e9triques Spark, MinIO, TimescaleDB
- 📈 **Grafana** : Dashboards de monitoring
- 📋 **Logs centralis\u00e9s** : ELK stack ou Loki
- 🔔 **Alerting** : Sur erreurs critiques, latence, espace disque

→ Documentation monitoring (à venir)

---

## 🆘 Autres Questions

### Q : J'ai une erreur, comment la r\u00e9soudre ?

**R** : Dans l'ordre :
1. Consulter [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. V\u00e9rifier cette FAQ
3. V\u00e9rifier les logs : `docker-compose logs`
4. Ex\u00e9cuter la checklist : [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md)
5. Contacter le support : data-engineering@bceao.int

---

### Q : O\u00f9 trouver plus de documentation ?

**R** : Index complet :
→ [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)

**Principaux guides** :
- [README_FR.md](./README_FR.md) - Documentation principale
- [QUICKSTART_FR.md](./QUICKSTART_FR.md) - D\u00e9marrage rapide
- [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md) - Transformations
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture technique
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - D\u00e9pannage

---

### Q : Comment contribuer au projet ?

**R** :
1. Lire [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Cr\u00e9er une branche : `git checkout -b feature/ma-fonctionnalit\u00e9`
3. D\u00e9velopper et tester
4. Commit : `git commit -m \"feat: ma nouvelle fonctionnalit\u00e9\"`
5. Push et créer une Pull Request

---

### Q : Quelle version du projet j'utilise ?

**R** :
```powershell
# V\u00e9rifier la version
cat VERSION_INFO.md | Select-String \"Version\"
```

**Version actuelle** : 1.1.0 (1er d\u00e9cembre 2025)

→ [CHANGELOG.md](./CHANGELOG.md) pour l'historique complet

---

## 📞 Contact

**Questions non r\u00e9solues ?**

**Email** : data-engineering@bceao.int  
**Projet** : Data Pipeline POC BCEAO  
**Version** : 1.1.0

---

**Auteur** : GitHub Copilot  
**Derni\u00e8re mise \u00e0 jour** : 1er d\u00e9cembre 2025  
**Version** : 1.0.0

---

💡 **Conseil** : Utilisez Ctrl+F pour rechercher rapidement dans cette FAQ !
