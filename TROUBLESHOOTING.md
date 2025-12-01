# 🔧 Guide de D\u00e9pannage - Data Pipeline POC BCEAO

**Objectif** : R\u00e9soudre les probl\u00e8mes courants du Data Pipeline

**Derni\u00e8re mise \u00e0 jour** : 1er d\u00e9cembre 2025

---

## 📋 Table des Mati\u00e8res

1. [Probl\u00e8mes Docker et Services](#1%EF%B8%8F⃣-probl\u00e8mes-docker-et-services)
2. [Probl\u00e8mes de Connexion](#2%EF%B8%8F⃣-probl\u00e8mes-de-connexion)
3. [Probl\u00e8mes dbt](#3%EF%B8%8F⃣-probl\u00e8mes-dbt)
4. [Probl\u00e8mes Spark et Iceberg](#4%EF%B8%8F⃣-probl\u00e8mes-spark-et-iceberg)
5. [Probl\u00e8mes MinIO (S3)](#5%EF%B8%8F⃣-probl\u00e8mes-minio-s3)
6. [Probl\u00e8mes UEMOA et TimescaleDB](#6%EF%B8%8F⃣-probl\u00e8mes-uemoa-et-timescaledb)
7. [Probl\u00e8mes de Performance](#7%EF%B8%8F⃣-probl\u00e8mes-de-performance)
8. [Probl\u00e8mes R\u00e9seau](#8%EF%B8%8F⃣-probl\u00e8mes-r\u00e9seau)

---

## 1️⃣ Probl\u00e8mes Docker et Services

### ❌ Probl\u00e8me : Les conteneurs ne d\u00e9marrent pas

**Symptômes** :
```
ERROR: Service 'spark-iceberg' failed to build
ERROR: for minio  Cannot start service minio
```

**Causes possibles** :
- Docker Desktop non d\u00e9marr\u00e9
- Ressources insuffisantes (RAM, CPU)
- Ports d\u00e9j\u00e0 utilis\u00e9s

**Solutions** :

#### Solution 1 : V\u00e9rifier Docker Desktop
```powershell
# V\u00e9rifier que Docker tourne
docker info

# Si erreur, d\u00e9marrer Docker Desktop
# Windows: Rechercher \"Docker Desktop\" dans le menu D\u00e9marrer
```

#### Solution 2 : Lib\u00e9rer de la m\u00e9moire
```powershell
# Arr\u00eater tous les conteneurs
docker-compose down

# Nettoyer les ressources non utilis\u00e9es
docker system prune -a --volumes

# Red\u00e9marrer
docker-compose up -d
```

#### Solution 3 : V\u00e9rifier les ports
```powershell
# V\u00e9rifier quel processus utilise un port (exemple : 9001)
netstat -ano | findstr :9001

# Tuer le processus si n\u00e9cessaire
taskkill /PID <numero_pid> /F
```

---

### ❌ Probl\u00e8me : Conteneur se red\u00e9marre en boucle

**Symptômes** :
```
docker ps
# Affiche \"Restarting\" ou \"Exited (1)\"
```

**Solutions** :

#### V\u00e9rifier les logs
```powershell
docker-compose logs spark-iceberg
docker-compose logs dbt
```

#### Red\u00e9marrer avec reconstruction
```powershell
docker-compose down
docker-compose build --no-cache spark-iceberg
docker-compose up -d
```

---

### ❌ Probl\u00e8me : Erreur \"Port is already allocated\"

**Symptômes** :
```
ERROR: Bind for 0.0.0.0:9001 failed: port is already allocated
```

**Solutions** :

#### Trouver et lib\u00e9rer le port
```powershell
# Identifier le processus
netstat -ano | findstr :9001

# Arr\u00eater le processus
taskkill /PID <numero> /F
```

#### Modifier le port dans docker-compose.yml
```yaml
# Si vous ne pouvez pas lib\u00e9rer le port, changez-le
services:
  minio:
    ports:
      - \"9002:9001\"  # Au lieu de 9001:9001
```

---

## 2️⃣ Probl\u00e8mes de Connexion

### ❌ Probl\u00e8me : MinIO Console inaccessible

**Symptômes** :
- http://localhost:9001 ne r\u00e9pond pas
- Erreur \"ERR_CONNECTION_REFUSED\"

**Solutions** :

#### V\u00e9rifier que MinIO tourne
```powershell
docker ps | Select-String minio
```

#### V\u00e9rifier les logs MinIO
```powershell
docker-compose logs minio
```

#### Red\u00e9marrer MinIO
```powershell
docker-compose restart minio
```

---

### ❌ Probl\u00e8me : TimescaleDB - \"Connection refused\"

**Symptômes** :
```
Connection refused: timescaledb:5432
Connection refused: localhost:5433
```

**Explications** :
- Port **5432** : communication INTERNE entre conteneurs Docker
- Port **5433** : acc\u00e8s EXTERNE depuis l'h\u00f4te Windows

**Solutions** :

#### Depuis un script PySpark (dans conteneur)
```python
# ✅ CORRECT : Utiliser port 5432 avec host \"timescaledb\"
jdbc_url = \"jdbc:postgresql://timescaledb:5432/monetary_policy_dm\"
```

#### Depuis Windows (psql, DBeaver)
```powershell
# ✅ CORRECT : Utiliser port 5433 avec host \"localhost\"
psql -h localhost -p 5433 -U postgres -d monetary_policy_dm
```

#### V\u00e9rifier que TimescaleDB tourne
```powershell
docker ps | Select-String timescale

# Tester la connexion
docker exec timescaledb psql -U postgres -c \"SELECT version();\"
```

---

### ❌ Probl\u00e8me : Jupyter Notebook inaccessible

**Symptômes** :
- http://localhost:8888 ne r\u00e9pond pas

**Solutions** :

#### V\u00e9rifier les logs Jupyter
```powershell
docker exec spark-iceberg cat /opt/spark/logs/jupyter.log
```

#### Red\u00e9marrer Spark
```powershell
docker-compose restart spark-iceberg

# Attendre 2 minutes puis tester
Start-Sleep -Seconds 120
curl http://localhost:8888
```

---

## 3️⃣ Probl\u00e8mes dbt

### ❌ Probl\u00e8me : \"Connection test failed\"

**Symptômes** :
```
docker exec dbt dbt debug
# ERROR: Could not connect to Spark Thrift Server
```

**Causes** :
- Thrift Server pas encore d\u00e9marr\u00e9 (attendre 2 minutes apr\u00e8s `docker-compose up`)
- Spark crash\u00e9

**Solutions** :

#### V\u00e9rifier que Thrift Server \u00e9coute
```powershell
docker exec spark-iceberg netstat -tuln | findstr 10000
```

**R\u00e9sultat attendu** : `tcp ... 0.0.0.0:10000 ... LISTEN`

#### V\u00e9rifier les logs Spark
```powershell
docker-compose logs spark-iceberg | Select-String \"ThriftBinaryCLIService\"
```

**R\u00e9sultat attendu** : `ThriftBinaryCLIService listening on ...10000`

#### Red\u00e9marrer et attendre
```powershell
docker-compose restart spark-iceberg
Start-Sleep -Seconds 120
docker exec dbt bash -c \"cd /usr/app/dbt && dbt debug\"
```

---

### ❌ Probl\u00e8me : dbt run \u00e9choue avec \"Table not found\"

**Symptômes** :
```
Compilation Error in model ... (models/gold/...)
  Table or view not found: default_gold.some_table
```

**Causes** :
- Namespace incorrect (`gold` au lieu de `default_gold`)
- Mod\u00e8le d\u00e9pendant non ex\u00e9cut\u00e9

**Solutions** :

#### V\u00e9rifier le namespace
```sql
-- ❌ INCORRECT
SELECT * FROM gold.table_name

-- ✅ CORRECT
SELECT * FROM default_gold.table_name
```

#### Ex\u00e9cuter dans l'ordre
```powershell
# Ex\u00e9cuter staging d'abord
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select staging\"

# Puis Gold
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run --select gold\"
```

---

### ❌ Probl\u00e8me : \"Column not found\" dans mod\u00e8le dbt

**Symptômes** :
```
  Column 'some_column' cannot be resolved
```

**Solutions** :

#### V\u00e9rifier les colonnes disponibles
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"DESCRIBE EXTENDED bronze.table_name;\"
```

#### Corriger le mod\u00e8le dbt
```sql
-- V\u00e9rifier le nom exact de la colonne (respect majuscules/minuscules)
SELECT 
    correct_column_name,  -- ✅
    -- wrong_column_name  -- ❌
FROM {{ source('bronze', 'table_name') }}
```

---

## 4️⃣ Probl\u00e8mes Spark et Iceberg

### ❌ Probl\u00e8me : \"No suitable driver found for jdbc:hive2\"

**Symptômes** :
```
java.sql.SQLException: No suitable driver found for jdbc:hive2://localhost:10000
```

**Cause** : Beeline pas configur\u00e9 correctement

**Solution** :

#### Utiliser beeline depuis le conteneur Spark
```powershell
# ✅ CORRECT
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000

# ❌ INCORRECT (depuis Windows)
beeline -u jdbc:hive2://localhost:10000
```

---

### ❌ Probl\u00e8me : \"Table or view not found\" (Iceberg)

**Symptômes** :
```
Table or view not found: bronze.indicateurs_economiques_uemoa
Table or view not found: default_gold.some_mart
```

**Causes** :
- Namespace incorrect
- Table pas encore cr\u00e9\u00e9e

**Solutions** :

#### V\u00e9rifier les namespaces existants
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SHOW NAMESPACES;\"
```

**R\u00e9sultat attendu** :
```
bronze
default
default_silver
default_gold
```

#### V\u00e9rifier les tables dans un namespace
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SHOW TABLES IN bronze;\"
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SHOW TABLES IN default_gold;\"
```

#### Cr\u00e9er la table si manquante
```powershell
# Pour UEMOA Bronze
docker exec spark-iceberg bash -lc \"cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/create_uemoa_table.py\"

# Pour Gold (via dbt)
docker exec dbt bash -c \"cd /usr/app/dbt && dbt run\"
```

---

### ❌ Probl\u00e8me : \"NoClassDefFoundError: com/amazonaws/AmazonClientException\"

**Symptômes** :
```
java.lang.NoClassDefFoundError: com/amazonaws/AmazonClientException
```

**Cause** : JARs AWS SDK manquants

**Solutions** :

#### V\u00e9rifier les JARs
```powershell
docker exec spark-iceberg ls -lh /opt/spark/extra-jars/
```

**R\u00e9sultat attendu** :
```
hadoop-aws-3.3.4.jar
aws-java-sdk-bundle-1.12.262.jar
```

#### T\u00e9l\u00e9charger les JARs manquants
Si les fichiers n'existent pas, les t\u00e9l\u00e9charger :
1. hadoop-aws-3.3.4.jar : https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
2. aws-java-sdk-bundle-1.12.262.jar : https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

Puis copier dans `./jars/` et red\u00e9marrer :
```powershell
docker-compose restart spark-iceberg
```

---

## 5️⃣ Probl\u00e8mes MinIO (S3)

### ❌ Probl\u00e8me : \"InvalidAccessKeyId\" ou \"403 Forbidden\"

**Symptômes** :
```
The AWS Access Key Id you provided does not exist in our records
Status Code: 403 Forbidden
```

**Cause** : Credentials MinIO incorrects

**Solutions** :

#### V\u00e9rifier le fichier .env
```env
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=SuperSecret123
```

#### V\u00e9rifier dans le script PySpark
```python
# Les credentials doivent correspondre au .env
spark = SparkSession.builder \
    .config(\"spark.hadoop.fs.s3a.access.key\", \"admin\") \
    .config(\"spark.hadoop.fs.s3a.secret.key\", \"SuperSecret123\") \
    .getOrCreate()
```

#### Tester la connexion MinIO
```powershell
docker exec mc mc ls bceao-data/
```

---

### ❌ Probl\u00e8me : \"Bucket does not exist\"

**Symptômes** :
```
NoSuchBucket: The specified bucket does not exist
```

**Solutions** :

#### Lister les buckets
```powershell
docker exec mc mc ls bceao-data/
```

#### Cr\u00e9er le bucket manquant
```powershell
docker exec mc mc mb bceao-data/bronze
docker exec mc mc mb bceao-data/lakehouse
```

---

## 6️⃣ Probl\u00e8mes UEMOA et TimescaleDB

### ❌ Probl\u00e8me : Erreur \"Driver PostgreSQL non trouv\u00e9\"

**Symptômes** :
```
java.sql.SQLException: No suitable driver found for jdbc:postgresql
```

**Cause** : Driver JDBC PostgreSQL manquant

**Solutions** :

#### Ex\u00e9cuter le script d'installation
```powershell
.\\setup_postgresql_driver.ps1
```

#### V\u00e9rifier l'installation
```powershell
docker exec spark-iceberg ls -lh /opt/spark/jars/postgresql-42.6.0.jar
```

---

### ❌ Probl\u00e8me : \"Namespace gold not found\" (UEMOA)

**Symptômes** :
```
Namespace or database 'gold' not found
```

**Cause** : Utilisation du mauvais namespace

**Solution** :

#### Utiliser `default_gold` au lieu de `gold`
```python
# ❌ INCORRECT
df = spark.table(\"gold.gold_mart_uemoa_monetary_dashboard\")

# ✅ CORRECT
df = spark.table(\"default_gold.gold_mart_uemoa_monetary_dashboard\")
```

---

### ❌ Probl\u00e8me : Tables UEMOA vides dans TimescaleDB

**Symptômes** :
```sql
SELECT COUNT(*) FROM gold_mart_uemoa_monetary_dashboard;
-- 0 rows
```

**Solutions** :

#### V\u00e9rifier que les tables existent dans Iceberg
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e \"SELECT COUNT(*) FROM default_gold.gold_mart_uemoa_monetary_dashboard;\"
```

#### R\u00e9ex\u00e9cuter la copie
```powershell
.\\run_copy_uemoa.ps1
```

---

## 7️⃣ Probl\u00e8mes de Performance

### ⚠️ Probl\u00e8me : Transformations dbt tr\u00e8s lentes

**Symptômes** :
- `dbt run` prend plus de 5 minutes
- Spark UI montre beaucoup de shuffle

**Solutions** :

#### Augmenter la m\u00e9moire Spark
Modifier `docker-compose.yml` :
```yaml
spark-iceberg:
  environment:
    - SPARK_DRIVER_MEMORY=4g
    - SPARK_EXECUTOR_MEMORY=4g
```

#### Partitionner les grandes tables
```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    partition_by=['year(date)']
  )
}}
```

---

### ⚠️ Probl\u00e8me : \"OutOfMemoryError: Java heap space\"

**Symptômes** :
```
java.lang.OutOfMemoryError: Java heap space
```

**Solutions** :

#### Augmenter la m\u00e9moire dans docker-compose.yml
```yaml
spark-iceberg:
  environment:
    - SPARK_DRIVER_MEMORY=8g
    - SPARK_EXECUTOR_MEMORY=8g
  deploy:
    resources:
      limits:
        memory: 12g
```

#### Red\u00e9marrer
```powershell
docker-compose down
docker-compose up -d
```

---

## 8️⃣ Probl\u00e8mes R\u00e9seau

### ❌ Probl\u00e8me : Conteneurs ne peuvent pas communiquer

**Symptômes** :
```
Could not connect to minio:9000
Could not connect to timescaledb:5432
```

**Solutions** :

#### V\u00e9rifier le r\u00e9seau Docker
```powershell
docker network ls
docker network inspect data-pipeline-poc_data-pipeline-net
```

#### Reconnecter les conteneurs
```powershell
docker-compose down
docker network prune
docker-compose up -d
```

---

## 🆘 Probl\u00e8mes Non R\u00e9solus

Si aucune solution ne fonctionne :

### 1. R\u00e9initialisation compl\u00e8te

```powershell
# ⚠️ ATTENTION : Supprime TOUTES les donn\u00e9es

# Arr\u00eater et supprimer tout
docker-compose down -v

# Supprimer les volumes
docker volume prune -f

# Nettoyer Docker
docker system prune -a --volumes -f

# Reconstruire from scratch
docker-compose build --no-cache
docker-compose up -d
```

### 2. V\u00e9rifier les logs complets

```powershell
# Sauvegarder tous les logs
docker-compose logs > logs_complets.txt
```

### 3. Consulter la documentation

- [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md) - Checklist compl\u00e8te
- [FAQ.md](./FAQ.md) - Questions fr\u00e9quentes
- [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) - Toute la documentation

### 4. Support

**Email** : data-engineering@bceao.int

---

## 📚 R\u00e9f\u00e9rences

- [Documentation Docker](https://docs.docker.com/)
- [Documentation Apache Spark](https://spark.apache.org/docs/latest/)
- [Documentation dbt](https://docs.getdbt.com/)
- [Documentation Apache Iceberg](https://iceberg.apache.org/)
- [Documentation MinIO](https://min.io/docs/)

---

**Auteur** : GitHub Copilot  
**Derni\u00e8re mise \u00e0 jour** : 1er d\u00e9cembre 2025  
**Version** : 1.0.0
