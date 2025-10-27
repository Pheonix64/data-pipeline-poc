# 🎯 Data Pipeline POC BCEAO - Vue d'Ensemble Rapide

**Version**: 1.0.0 | **Statut**: ✅ Production Ready

---

## 📊 En Un Coup d'Œil

```
┌─────────────────────────────────────────────────────────┐
│         DATA PIPELINE POC - BCEAO                       │
│    Architecture Moderne Data Lakehouse                  │
│    Pattern Médaillon (Bronze → Silver → Gold)          │
└─────────────────────────────────────────────────────────┘

🥉 BRONZE          →    🥈 SILVER         →    🥇 GOLD
Données Brutes          Données Nettoyées     Données Analytiques
20 événements           20 événements         20 événements enrichis
6 utilisateurs          6 utilisateurs        + info utilisateurs
```

---

## ⚡ Démarrage en 3 Minutes

```bash
# 1. Créer le fichier .env (copier .env.example)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# 2. Démarrer les services
docker-compose up -d

# 3. Vérifier l'installation
docker-compose ps
```

**Accès rapides** :
- 🖥️ MinIO Console: http://localhost:9001
- 📓 Jupyter: http://localhost:8888
- ⚡ Spark UI: http://localhost:4040

---

## 🏗️ Stack Technique

| Composant | Rôle | Port |
|-----------|------|------|
| **MinIO** | Stockage S3 | 9000, 9001 |
| **Apache Iceberg** | Format de table ACID | - |
| **Spark 3.5** | Traitement de données | 4040, 8888, 10000 |
| **dbt** | Transformations SQL | - |
| **TimescaleDB** | Time-series DB | 5433 |
| **ChromaDB** | Vector DB | 8010 |

---

## 📈 Architecture des Données

### Flux de Données

```
Sources de Données
        ↓
┌──────────────────┐
│  BRONZE LAYER    │  ← Données brutes (append-only)
│  bronze.*        │
└────────┬─────────┘
         │ dbt clean & validate
         ↓
┌──────────────────┐
│  SILVER LAYER    │  ← Données nettoyées (validated)
│  default_silver.*│
└────────┬─────────┘
         │ dbt enrich & aggregate
         ↓
┌──────────────────┐
│   GOLD LAYER     │  ← Données analytiques (enriched)
│  default_gold.*  │
└────────┬─────────┘
         │
         ↓
   BI / Analytics / ML
```

### Tables Principales

#### 🥉 Bronze
```sql
bronze.raw_events    -- Événements système bruts
bronze.raw_users     -- Utilisateurs système bruts
```

#### 🥈 Silver
```sql
default_silver.stg_events  -- Événements nettoyés
default_silver.stg_users   -- Utilisateurs nettoyés
```

#### 🥇 Gold
```sql
default_gold.fct_events_enriched  -- Événements + données utilisateurs
```

---

## 🚀 Commandes Essentielles

### Gestion Système

```bash
# Démarrer
docker-compose up -d

# Statut
docker-compose ps

# Logs
docker-compose logs -f spark-iceberg

# Arrêter
docker-compose down
```

### dbt - Transformations

```bash
# Exécuter toutes les transformations
docker exec dbt dbt run

# Tests de qualité
docker exec dbt dbt test

# Vérifier la connexion
docker exec dbt dbt debug
```

### Spark SQL

```bash
# Lister les namespaces
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW NAMESPACES;"

# Compter les événements
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) FROM bronze.raw_events;"

# Requête sur Gold
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT * FROM default_gold.fct_events_enriched LIMIT 5;"
```

---

## 📚 Documentation

| Document | Description | Temps |
|----------|-------------|-------|
| [📖 DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) | Index de toute la documentation | 5 min |
| [⚡ QUICKSTART_FR.md](./QUICKSTART_FR.md) | Guide de démarrage | 15 min |
| [📘 README_FR.md](./README_FR.md) | Documentation complète | 45 min |
| [🔄 TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md) | Guide transformations | 30 min |
| [📋 VERSION_INFO.md](./VERSION_INFO.md) | Informations de version | 20 min |

---

## 🎯 Cas d'Usage Typiques

### 1. Charger des Données Brutes

```python
# Via Jupyter Notebook (http://localhost:8888)
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Data Loader").getOrCreate()

# Insérer dans Bronze
spark.sql("""
    INSERT INTO bronze.raw_events VALUES 
    (100, 'login', 101, current_timestamp(), 'ip:192.168.1.100')
""")
```

### 2. Transformer Bronze → Silver → Gold

```bash
# Exécuter les transformations dbt
docker exec dbt dbt run

# Résultat:
# ✓ stg_events (Bronze → Silver)
# ✓ stg_users (Bronze → Silver)
# ✓ fct_events_enriched (Silver → Gold)
```

### 3. Analyser les Données Gold

```python
# Via Jupyter ou Beeline
df = spark.sql("""
    SELECT 
        event_type,
        user_name,
        COUNT(*) as event_count
    FROM default_gold.fct_events_enriched
    GROUP BY event_type, user_name
    ORDER BY event_count DESC
""")
df.show()
```

### 4. Explorer avec Time Travel

```python
# Iceberg Time Travel - voir données à un moment précis
spark.sql("""
    SELECT * FROM bronze.raw_events
    VERSION AS OF 1234567890
""").show()

# Voir l'historique des snapshots
spark.sql("""
    SELECT * FROM bronze.raw_events.snapshots
""").show()
```

---

## 📊 Métriques Clés

### Données de Démonstration

| Layer | Tables | Lignes | Format |
|-------|--------|--------|--------|
| Bronze | 2 | 26 | Iceberg/Parquet |
| Silver | 2 | 26 | Iceberg/Parquet |
| Gold | 1 | 20 | Iceberg/Parquet |

### Performance

| Opération | Temps Moyen |
|-----------|-------------|
| Démarrage système | ~2 minutes |
| Transformation dbt | ~10-30 secondes |
| Requête simple SQL | < 1 seconde |
| Time travel query | < 2 secondes |

---

## 🔧 Configuration Minimale

### Fichier .env

```env
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123
POSTGRES_DB=datamart
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
```

### Prérequis Système

- **RAM** : 8 GB minimum (16 GB recommandé)
- **CPU** : 4 cores minimum
- **Disque** : 10 GB espace libre
- **Docker** : Version 20.10+
- **Docker Compose** : Version 2.0+

---

## 🎨 Fonctionnalités Clés

### ✅ Implémenté

- [x] Architecture Médaillon (Bronze/Silver/Gold)
- [x] Tables Iceberg avec ACID
- [x] Transformations dbt
- [x] Jupyter Notebooks
- [x] Spark Thrift Server (JDBC/ODBC)
- [x] MinIO S3-compatible storage
- [x] TimescaleDB pour time-series
- [x] ChromaDB pour embeddings
- [x] Données de test pré-chargées
- [x] Documentation complète

### 🔄 Intégrations Possibles

- [ ] Airbyte pour ingestion (guide disponible)
- [ ] Airflow pour orchestration
- [ ] Superset pour visualisation
- [ ] Great Expectations pour data quality
- [ ] MLflow pour ML lifecycle

---

## 🐛 Dépannage Rapide

| Problème | Solution |
|----------|----------|
| Services ne démarrent pas | `docker-compose down && docker-compose up -d` |
| dbt ne se connecte pas | Attendre 2 min après démarrage Spark |
| Jupyter inaccessible | `docker-compose restart spark-iceberg` |
| Données manquantes | Vérifier logs: `docker-compose logs spark-iceberg` |

→ Plus de détails : [QUICKSTART_FR.md - Dépannage](./QUICKSTART_FR.md#résolution-des-problèmes-courants)

---

## 🎓 Apprentissage Rapide

### Parcours 30 Minutes

1. **5 min** : Lire ce document
2. **10 min** : Démarrer le système ([QUICKSTART_FR.md](./QUICKSTART_FR.md))
3. **10 min** : Explorer Jupyter et MinIO
4. **5 min** : Exécuter première transformation dbt

### Parcours 2 Heures

1. Suivre parcours 30 minutes
2. Lire [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)
3. Créer modèle dbt personnalisé
4. Explorer requêtes Spark SQL avancées

---

## 📞 Support

### Documentation
- 📖 [Index Documentation](./DOCUMENTATION_INDEX.md)
- 📘 [Documentation Complète](./README_FR.md)
- ⚡ [Quick Start](./QUICKSTART_FR.md)

### Ressources Externes
- [Apache Iceberg](https://iceberg.apache.org/)
- [Apache Spark](https://spark.apache.org/)
- [dbt](https://docs.getdbt.com/)
- [MinIO](https://min.io/docs/)

---

## 🏆 Quick Wins

**Premier jour** :
- ✅ Système opérationnel
- ✅ Première transformation dbt
- ✅ Première requête SQL sur Gold layer

**Première semaine** :
- ✅ Modèles dbt personnalisés
- ✅ Intégration Airbyte (optionnel)
- ✅ Dashboards de données

---

## 📅 Dernière Mise à Jour

**Date** : 27 octobre 2025  
**Version** : 1.0.0  
**Statut** : Production Ready

Voir [CHANGELOG.md](./CHANGELOG.md) pour l'historique complet.

---

**🚀 Prêt à commencer ?**

```bash
# Clone ou navigue vers le projet
cd data-pipeline-poc

# Crée le fichier .env
cp .env.example .env

# Démarre tout !
docker-compose up -d

# Explore !
open http://localhost:9001  # MinIO
open http://localhost:8888  # Jupyter
open http://localhost:4040  # Spark UI
```

**Bon voyage dans le monde des Data Lakehouses ! 🎉**
