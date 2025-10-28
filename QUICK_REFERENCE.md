# QUICK REFERENCE - Guide de référence rapide

Guide de référence rapide pour les commandes courantes du projet Data Pipeline POC BCEAO.

## 🚀 Démarrage rapide

```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état des services
docker-compose ps

# Voir les logs en temps réel
docker-compose logs -f

# Arrêter tous les services
docker-compose down
```

## 📊 dbt - Transformations de données

### Commandes de base

```bash
# Exécuter tous les modèles
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"

# Exécuter un modèle spécifique
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select mon_modele"

# Exécuter plusieurs modèles par tag
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select tag:gold"

# Exécuter un modèle et ses dépendances en amont
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select +mon_modele"

# Exécuter un modèle et ses dépendances en aval
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select mon_modele+"

# Mode full refresh (recharger toutes les données)
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --full-refresh"
```

### Tests

```bash
# Exécuter tous les tests
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"

# Tester un modèle spécifique
docker exec dbt bash -c "cd /usr/app/dbt && dbt test --select mon_modele"

# Tester uniquement les sources
docker exec dbt bash -c "cd /usr/app/dbt && dbt test --select source:*"
```

### Documentation

```bash
# Générer la documentation
docker exec dbt bash -c "cd /usr/app/dbt && dbt docs generate"

# Servir la documentation (pas disponible dans conteneur)
# Alternative: Copier catalog.json et index.html localement
```

### Debug

```bash
# Vérifier la connexion
docker exec dbt bash -c "cd /usr/app/dbt && dbt debug"

# Compiler sans exécuter (voir le SQL généré)
docker exec dbt bash -c "cd /usr/app/dbt && dbt compile --select mon_modele"

# Voir le SQL compilé
docker exec dbt bash -c "cat /usr/app/dbt/target/compiled/dbt_project/models/chemin/mon_modele.sql"

# Logs dbt
docker exec dbt bash -c "cat /usr/app/dbt/logs/dbt.log | tail -n 50"
```

## ⚡ Spark - Traitement de données

### Spark Submit

```bash
# Exécuter un script PySpark
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/mon_script.py"

# Avec arguments
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/mon_script.py arg1 arg2"

# Avec configuration custom
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  --conf spark.driver.memory=4g \
  --conf spark.executor.memory=8g \
  /tmp/mon_script.py"
```

### PySpark Shell

```bash
# Lancer PySpark interactif
docker exec -it spark-iceberg /opt/spark/bin/pyspark

# Commandes dans PySpark
# >>> df = spark.read.parquet("s3a://lakehouse/bronze/...")
# >>> df.show()
# >>> df.printSchema()
# >>> df.count()
```

### Beeline (SQL CLI)

```bash
# Connexion Beeline
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000

# Requête en une ligne
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) FROM bronze.indicateurs_economiques_uemoa;"

# Plusieurs requêtes
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW DATABASES; SHOW TABLES IN bronze;"

# Requête depuis un fichier
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -f /tmp/ma_requete.sql
```

### Spark UI

```bash
# Accéder à Spark UI
# Navigateur: http://localhost:4040

# Jobs actifs
# http://localhost:4040/jobs/

# Stages et DAG
# http://localhost:4040/stages/

# Storage (tables cached)
# http://localhost:4040/storage/

# Environment (configuration)
# http://localhost:4040/environment/
```

## 🗄️ MinIO - Stockage S3

### mc (MinIO Client)

```bash
# Lister les buckets
docker exec mc mc ls bceao-data/

# Lister le contenu d'un bucket
docker exec mc mc ls bceao-data/lakehouse/

# Lister récursivement
docker exec mc mc ls bceao-data/lakehouse/bronze/ --recursive

# Obtenir des infos sur un objet
docker exec mc mc stat bceao-data/lakehouse/bronze/indicateurs_economiques_uemoa/

# Télécharger un fichier
docker exec mc mc cp bceao-data/lakehouse/bronze/mon_fichier.parquet /tmp/

# Uploader un fichier
docker exec mc mc cp /tmp/mon_fichier.parquet bceao-data/lakehouse/bronze/

# Synchroniser un répertoire (backup)
docker exec mc mc mirror bceao-data/lakehouse /backup/lakehouse

# Obtenir des stats serveur
docker exec mc mc admin info bceao-data
```

### MinIO Console

```bash
# Accéder à l'interface web
# Navigateur: http://localhost:9001
# Login: admin
# Password: SuperSecret123

# Features web:
# - Browser: Naviguer dans les buckets
# - Monitoring: Métriques en temps réel
# - Identity: Gestion des utilisateurs et policies
# - Settings: Configuration serveur
```

## 🧊 Iceberg - Tables ACID

### Catalog Operations

```sql
-- Lister tous les namespaces
SHOW NAMESPACES;

-- Créer un namespace
CREATE NAMESPACE IF NOT EXISTS mon_namespace;

-- Lister les tables d'un namespace
SHOW TABLES IN bronze;

-- Obtenir le schéma d'une table
DESCRIBE bronze.indicateurs_economiques_uemoa;

-- Obtenir les détails étendus
DESCRIBE EXTENDED bronze.indicateurs_economiques_uemoa;
```

### Table Operations

```sql
-- Créer une table Iceberg
CREATE TABLE mon_namespace.ma_table (
    id BIGINT,
    nom STRING,
    valeur DECIMAL(18,2)
) USING iceberg
PARTITIONED BY (annee);

-- Insérer des données
INSERT INTO mon_namespace.ma_table VALUES (1, 'test', 100.50);

-- Créer depuis SELECT
CREATE TABLE mon_namespace.ma_nouvelle_table
USING iceberg
AS SELECT * FROM mon_namespace.ma_table;

-- Créer ou remplacer
CREATE OR REPLACE TABLE mon_namespace.ma_table
USING iceberg
AS SELECT * FROM source_table;
```

### Time Travel

```sql
-- Voir l'historique des snapshots
SELECT * FROM mon_namespace.ma_table.snapshots;

-- Requête à un timestamp spécifique
SELECT * FROM mon_namespace.ma_table
TIMESTAMP AS OF '2024-01-15 10:30:00';

-- Requête à un snapshot ID spécifique
SELECT * FROM mon_namespace.ma_table
VERSION AS OF 8901234567890123456;

-- Rollback à un snapshot précédent
CALL local.system.rollback_to_snapshot(
    'mon_namespace.ma_table',
    8901234567890123456
);
```

### Maintenance

```sql
-- Expirer les vieux snapshots (libérer espace)
CALL local.system.expire_snapshots(
    table => 'mon_namespace.ma_table',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 100
);

-- Compacter les petits fichiers
CALL local.system.rewrite_data_files(
    table => 'mon_namespace.ma_table',
    strategy => 'binpack',
    options => map('target-file-size-bytes', '536870912')
);

-- Supprimer les fichiers orphelins
CALL local.system.remove_orphan_files(
    table => 'mon_namespace.ma_table',
    older_than => TIMESTAMP '2024-01-01 00:00:00'
);
```

## 🐳 Docker - Gestion des conteneurs

### Conteneurs

```bash
# Lister tous les conteneurs
docker ps -a

# Voir les logs d'un conteneur
docker logs spark-iceberg

# Logs en temps réel
docker logs -f spark-iceberg

# Logs des 100 dernières lignes
docker logs --tail=100 spark-iceberg

# Entrer dans un conteneur
docker exec -it spark-iceberg bash

# Redémarrer un conteneur
docker restart spark-iceberg

# Arrêter un conteneur
docker stop spark-iceberg

# Démarrer un conteneur
docker start spark-iceberg
```

### Images

```bash
# Lister les images
docker images

# Reconstruire une image
docker-compose build spark-iceberg

# Reconstruire sans cache
docker-compose build --no-cache spark-iceberg

# Supprimer une image
docker rmi data-pipeline-poc_spark-iceberg
```

### Volumes

```bash
# Lister les volumes
docker volume ls

# Inspecter un volume
docker volume inspect data-pipeline-poc_minio_data

# Supprimer un volume (attention: perte de données!)
docker volume rm data-pipeline-poc_minio_data

# Supprimer tous les volumes non utilisés
docker volume prune
```

### Nettoyage

```bash
# Supprimer conteneurs arrêtés
docker container prune

# Supprimer images non utilisées
docker image prune

# Supprimer volumes non utilisés
docker volume prune

# Nettoyage complet (ATTENTION: supprime tout!)
docker system prune -a --volumes
```

## 📦 Copier des fichiers

### Vers conteneur

```bash
# Copier un fichier vers conteneur
docker cp mon_fichier.py spark-iceberg:/tmp/

# Copier un répertoire
docker cp mon_dossier/ spark-iceberg:/tmp/

# Copier vers dbt
docker cp mon_modele.sql dbt:/usr/app/dbt/models/
```

### Depuis conteneur

```bash
# Copier depuis conteneur vers local
docker cp spark-iceberg:/tmp/resultat.csv ./

# Copier logs dbt
docker cp dbt:/usr/app/dbt/logs/dbt.log ./logs/

# Copier catalog dbt
docker cp dbt:/usr/app/dbt/target/catalog.json ./docs/
```

## 🔍 Diagnostic

### Vérifier la santé du système

```bash
# Vérifier tous les services
docker-compose ps

# Vérifier l'utilisation des ressources
docker stats

# Vérifier l'espace disque Docker
docker system df

# Tester la connexion MinIO
docker exec mc mc admin info bceao-data

# Tester la connexion Spark
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit --version"

# Tester la connexion dbt
docker exec dbt bash -c "cd /usr/app/dbt && dbt debug"
```

### Problèmes courants

```bash
# Port déjà utilisé
# Solution: Identifier et tuer le processus
netstat -ano | findstr :9000  # Windows
lsof -i :9000                 # Linux/Mac
# Puis kill le processus ou changer le port dans docker-compose.yml

# Conteneur ne démarre pas
docker logs nom_conteneur
# Vérifier les logs pour identifier l'erreur

# Problème de connexion réseau
docker network ls
docker network inspect data-pipeline-poc_default

# Problème de permissions
# Windows: Vérifier que Docker Desktop a accès aux dossiers partagés
# Linux: sudo chown -R $USER:$USER ./
```

## 📊 Monitoring

### Métriques Spark

```bash
# Voir les applications actives
docker exec spark-iceberg bash -lc "ls /opt/spark/work"

# Voir la configuration Spark
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SET -v;" | grep spark
```

### Métriques MinIO

```bash
# Taille totale des buckets
docker exec mc mc du bceao-data/lakehouse

# Nombre d'objets
docker exec mc mc ls bceao-data/lakehouse --recursive | wc -l
```

### Métriques dbt

```bash
# Dernière exécution
docker exec dbt bash -c "cat /usr/app/dbt/logs/dbt.log | grep 'Completed successfully'"

# Temps d'exécution par modèle
docker exec dbt bash -c "cat /usr/app/dbt/target/run_results.json" | jq '.results[] | {name: .unique_id, time: .execution_time}'
```

## 🔧 Configuration

### Fichiers de configuration importants

```bash
# Spark configuration
./spark-defaults.conf

# dbt profiles
./dbt_project/profiles.yml

# dbt project
./dbt_project/dbt_project.yml

# Docker services
./docker-compose.yml

# Environnement
./.env
```

### Éditer et recharger configuration

```bash
# Éditer la config Spark
vim spark-defaults.conf

# Reconstruire et redémarrer
docker-compose build spark-iceberg
docker-compose restart spark-iceberg

# Éditer les profiles dbt
vim dbt_project/profiles.yml

# Pas besoin de rebuild, juste reload
docker exec dbt bash -c "cd /usr/app/dbt && dbt debug"
```

## 📚 Ressources

### Documentation

- README.md: Vue d'ensemble du projet
- ARCHITECTURE.md: Architecture technique détaillée
- DEPLOYMENT_GUIDE.md: Guide de déploiement complet
- CONTRIBUTING.md: Guide de contribution
- CHANGELOG.md: Historique des versions

### URLs utiles

```
MinIO Console:      http://localhost:9001
Jupyter Notebook:   http://localhost:8888
Spark UI:          http://localhost:4040
Iceberg REST:      http://localhost:8181
```

### Credentials par défaut

```
MinIO:
  - User: admin
  - Password: SuperSecret123

PostgreSQL/TimescaleDB:
  - Database: monetary_policy_dm
  - User: postgres
  - Password: PostgresPass123
```

## 🆘 Aide

### Obtenir de l'aide

```bash
# Aide dbt
docker exec dbt bash -c "dbt --help"
docker exec dbt bash -c "dbt run --help"

# Aide Spark
docker exec spark-iceberg /opt/spark/bin/spark-submit --help

# Aide mc (MinIO)
docker exec mc mc --help
docker exec mc mc ls --help
```

### Communauté

- GitHub Issues: Signaler des bugs
- GitHub Discussions: Poser des questions
- Email: data-engineering@bceao.int

---

**Astuce**: Ajoutez cette page à vos favoris pour un accès rapide ! 🔖
