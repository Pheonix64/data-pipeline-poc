# Changelog - Data Pipeline POC BCEAO

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [1.0.0] - 2025-10-27

### 🎉 Version Initiale - Production Ready

#### ✨ Ajouté

**Infrastructure**
- Architecture Data Lakehouse complète avec pattern Médaillon (Bronze, Silver, Gold)
- Conteneurs Docker pour tous les services (MinIO, Spark, Iceberg, dbt, TimescaleDB, ChromaDB)
- Configuration Docker Compose avec healthchecks et dépendances
- Réseau Docker dédié pour l'isolation des services
- Volumes persistants pour toutes les données

**Stockage et Catalogue**
- MinIO comme stockage objet compatible S3
- Buckets automatiquement créés (bronze, silver, gold, lakehouse)
- Iceberg REST Catalog pour la gestion des métadonnées
- Support complet des transactions ACID avec Iceberg

**Traitement de Données**
- Apache Spark 3.5 avec support Iceberg
- Spark Thrift Server pour connexions JDBC/ODBC
- Jupyter Notebook pour analyses interactives
- Configuration Spark optimisée pour Iceberg et S3

**Transformations**
- dbt-spark configuré pour transformations SQL
- Modèles staging (Bronze → Silver): `stg_events`, `stg_users`
- Modèles marts (Silver → Gold): `fct_events_enriched`
- Tests de qualité de données dbt
- Package dbt_utils installé

**Couches de Données**

*Bronze Layer*:
- `bronze.raw_events` - Événements bruts
- `bronze.raw_users` - Utilisateurs bruts
- Script d'initialisation avec données de test (20 événements, 6 utilisateurs)

*Silver Layer*:
- `default_silver.stg_events` - Événements nettoyés
- `default_silver.stg_users` - Utilisateurs nettoyés
- Validation des données (NOT NULL constraints)
- Métadonnées de traçabilité (dbt_loaded_at)

*Gold Layer*:
- `default_gold.fct_events_enriched` - Événements enrichis avec données utilisateurs
- Jointures entre événements et utilisateurs
- Données dénormalisées pour performance analytique

**Documentation**
- README.md (version anglaise)
- README_FR.md (documentation complète en français)
- QUICKSTART_FR.md (guide de démarrage rapide)
- TRANSFORMATION_GUIDE_FR.md (guide détaillé des transformations)
- AIRBYTE_MINIO_INTEGRATION.md (guide d'intégration Airbyte)
- MINIO_STRUCTURE_GUIDE.md (organisation des buckets)
- VERIFICATION_REPORT.md (rapport de vérification système)
- VERSION_INFO.md (informations de version détaillées)
- CHANGELOG.md (ce fichier)

**Scripts et Automatisation**
- `init-lakehouse.sh` - Initialisation automatique du lakehouse
- Création automatique des namespaces Iceberg
- Chargement automatique des données de test
- Démarrage automatique de Jupyter et Thrift Server

#### 🔧 Configuration

**Fichiers de Configuration**
- `docker-compose.yml` - Orchestration de 6 services
- `spark-defaults.conf` - Configuration Spark pour Iceberg
- `spark.Dockerfile` - Image personnalisée Spark avec Iceberg
- `dbt_project.yml` - Configuration projet dbt
- `profiles.yml` - Profils de connexion dbt
- `.env.example` - Template des variables d'environnement

**Ports Exposés**
- 9000: MinIO API (S3)
- 9001: MinIO Console Web
- 8181: Iceberg REST Catalog
- 8888: Jupyter Notebook
- 4040: Spark UI
- 10000: Spark Thrift Server
- 5433: TimescaleDB
- 8010: ChromaDB

#### 📊 Métriques

**Données de Test**
- 20 événements initiaux (login, page_view, purchase, logout)
- 6 utilisateurs de test
- Distribution temporelle sur janvier 2024
- Événements distribués sur 3 utilisateurs

**Performance**
- Temps d'initialisation: ~2 minutes
- Temps de transformation dbt: ~10-30 secondes
- Support jusqu'à des milliers de tables Iceberg
- Optimisation automatique des fichiers Parquet

#### 🎯 Fonctionnalités Clés

**Apache Iceberg**
- Support ACID complet
- Time travel (voyage dans le temps)
- Évolution de schéma sans interruption
- Optimisation automatique des fichiers
- Partition pruning efficace

**dbt**
- Transformations SQL modulaires
- Tests de qualité de données
- Documentation automatique
- Lignage des données
- Support Iceberg natif

**Jupyter Notebooks**
- PySpark configuré avec Iceberg
- Support des requêtes SQL Spark
- Analyses interactives
- Visualisations de données

#### 🔐 Sécurité

- Isolation réseau Docker
- Variables d'environnement pour credentials
- Accès MinIO avec credentials configurables
- Pas d'exposition de services critiques sur Internet

#### 📝 Qualité de Code

**Tests dbt**
- Tests de NOT NULL sur event_id
- Tests de NOT NULL et UNIQUE sur user_id
- Validation des transformations

**Documentation dbt**
- Descriptions pour toutes les tables
- Descriptions pour toutes les colonnes
- Schémas YAML pour sources et modèles

#### 🌐 Langues

- Documentation principale: Français
- Documentation secondaire: Anglais
- Code et commentaires: Anglais
- Logs système: Anglais

---

## [Non publié]

### 🔄 Améliorations Futures Possibles

#### En Considération
- [ ] Intégration Airflow pour orchestration avancée
- [ ] Ajout de Great Expectations pour data quality
- [ ] Intégration Superset/Metabase pour visualisation
- [ ] Support MLflow pour ML lifecycle
- [ ] Ajout de notebooks d'exemple avancés
- [ ] Configuration CI/CD
- [ ] Tests d'intégration automatisés
- [ ] Monitoring avec Prometheus/Grafana
- [ ] Backup automatique des métadonnées

#### Intégrations Tierces
- [ ] Airbyte (guide disponible)
- [ ] Kafka pour streaming
- [ ] Databricks (optionnel)
- [ ] AWS S3 (remplacement MinIO)
- [ ] Azure Blob Storage

#### Optimisations
- [ ] Partitioning automatique des tables
- [ ] Compaction automatique Iceberg
- [ ] Cache de résultats Spark
- [ ] Optimisation des requêtes SQL

---

## Guide de Versioning

Ce projet utilise le [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Changements incompatibles avec versions précédentes
- **MINOR** (0.X.0): Nouvelles fonctionnalités rétro-compatibles
- **PATCH** (0.0.X): Corrections de bugs rétro-compatibles

### Exemples de Changements

**MAJOR** (1.0.0 → 2.0.0):
- Changement d'architecture majeur
- Migration de format de données
- Suppression de fonctionnalités existantes

**MINOR** (1.0.0 → 1.1.0):
- Ajout de nouvelles tables ou modèles
- Nouveaux services Docker
- Nouvelles fonctionnalités dbt

**PATCH** (1.0.0 → 1.0.1):
- Corrections de bugs
- Améliorations de documentation
- Optimisations mineures

---

## Notes de Migration

### De 0.x à 1.0.0

**Pas de version précédente** - Il s'agit de la première version stable.

Pour les futures migrations, consultez cette section pour les instructions de mise à jour.

---

## Support

Pour toute question ou problème:

1. Consultez la [documentation complète](./README_FR.md)
2. Vérifiez le [guide de dépannage](./QUICKSTART_FR.md#résolution-des-problèmes-courants)
3. Consultez le [rapport de vérification](./VERIFICATION_REPORT.md)

---

**Légende**:
- ✨ Ajouté: Nouvelles fonctionnalités
- 🔧 Modifié: Changements aux fonctionnalités existantes
- 🐛 Corrigé: Corrections de bugs
- 🗑️ Supprimé: Fonctionnalités retirées
- 🔐 Sécurité: Correctifs de sécurité
- 📝 Documentation: Améliorations de documentation
- ⚡ Performance: Optimisations de performance

---

**Dernière mise à jour**: 27 octobre 2025
