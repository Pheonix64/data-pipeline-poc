# Guide de Démarrage Rapide - Data Pipeline POC

## Prérequis

- Docker Desktop installé et en cours d'exécution
- Docker Compose
- Au moins 8 GB de RAM disponible
- Ports disponibles: 4040, 8888, 9000, 9001, 8181, 10000, 5433, 8010

## Étape 1: Configuration Initiale

### 1.1 Créer le fichier .env

Créez un fichier `.env` à la racine du projet:

```env
# MinIO Configuration
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password123

# PostgreSQL/TimescaleDB Configuration
POSTGRES_DB=datamart
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
```

### 1.2 Vérifier la structure des répertoires

```
data-pipeline-poc/
├── docker-compose.yml
├── spark.Dockerfile
├── spark-defaults.conf
├── .env
├── init-scripts/
│   └── init-lakehouse.sh
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   └── models/
└── (autres dossiers créés automatiquement)
```

## Étape 2: Démarrage du Système

### 2.1 Construire les images Docker

```powershell
docker-compose build
```

**Durée**: 5-10 minutes (première fois)

### 2.2 Démarrer tous les services

```powershell
docker-compose up -d
```

**Vérification des services**:
```powershell
docker-compose ps
```

Tous les services doivent afficher "Up" ou "Healthy".

### 2.3 Attendre l'initialisation complète

L'initialisation du lakehouse prend environ 1-2 minutes.

**Vérifier les logs**:
```powershell
docker-compose logs -f spark-iceberg
```

Attendez de voir:
```
=== Initialisation terminée avec succès ! ===
HiveThriftServer2 started
```

## Étape 3: Vérification de l'Installation

### 3.1 Vérifier MinIO

**Accès**: http://localhost:9001

**Connexion**: Utilisez les identifiants du fichier .env

**Vérification**: Les buckets `bronze`, `silver`, `gold`, et `lakehouse` doivent exister.

### 3.2 Vérifier Spark UI

**Accès**: http://localhost:4040

**Vérification**: L'interface Spark Thrift Server doit s'afficher.

### 3.3 Vérifier Jupyter Notebook

**Accès**: http://localhost:8888

**Vérification**: L'interface JupyterLab doit s'afficher (pas de mot de passe requis).

### 3.4 Vérifier les tables Iceberg

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW NAMESPACES;"
```

**Résultat attendu**:
```
bronze
default
default_default_gold
default_default_silver
```

### 3.5 Vérifier les données de test

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.raw_events;"
```

**Résultat attendu**: 20 lignes

## Étape 4: Première Transformation avec dbt

### 4.1 Vérifier la connexion dbt

```powershell
docker exec dbt dbt debug
```

**Résultat attendu**: "All checks passed!"

### 4.2 Exécuter les transformations

```powershell
docker exec dbt dbt run
```

**Résultat attendu**:
```
Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3
```

### 4.3 Vérifier les tables créées

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN default_default_silver;"
```

**Résultat attendu**:
```
stg_events
stg_users
```

### 4.4 Interroger les données transformées

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT * FROM default_default_gold.fct_events_enriched LIMIT 5;"
```

## Étape 5: Explorer avec Jupyter

### 5.1 Ouvrir Jupyter

Accédez à http://localhost:8888

### 5.2 Créer un nouveau notebook Python

**Nouveau** → **Python 3**

### 5.3 Tester la connexion Spark

```python
from pyspark.sql import SparkSession

# Créer une session Spark
spark = SparkSession.builder \
    .appName("Test Connection") \
    .getOrCreate()

# Afficher les namespaces
spark.sql("SHOW NAMESPACES").show()

# Lire des données depuis Bronze
df = spark.sql("SELECT * FROM bronze.raw_events LIMIT 10")
df.show()
```

### 5.4 Exécuter le notebook

Appuyez sur **Shift+Enter** pour exécuter chaque cellule.

## Commandes Utiles

### Gestion des Services

```powershell
# Démarrer tous les services
docker-compose up -d

# Arrêter tous les services
docker-compose down

# Redémarrer un service spécifique
docker-compose restart spark-iceberg

# Voir les logs d'un service
docker-compose logs -f spark-iceberg

# Voir l'état des services
docker-compose ps
```

### dbt

```powershell
# Exécuter tous les modèles
docker exec dbt dbt run

# Exécuter uniquement les modèles staging
docker exec dbt dbt run --select staging

# Exécuter les tests
docker exec dbt dbt test

# Vérifier la connexion
docker exec dbt dbt debug
```

### Requêtes SQL

```powershell
# Se connecter via Beeline
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000

# Exécuter une requête directe
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.raw_events;"
```

## Résolution des Problèmes Courants

### Problème: Les services ne démarrent pas

**Solution**:
```powershell
# Vérifier les logs
docker-compose logs

# Reconstruire les images
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Problème: MinIO n'est pas accessible

**Solution**:
```powershell
# Vérifier que MinIO est en cours d'exécution
docker-compose ps minio

# Redémarrer MinIO
docker-compose restart minio

# Vérifier les logs
docker-compose logs minio
```

### Problème: dbt ne peut pas se connecter

**Solution**:
```powershell
# Vérifier que Thrift Server écoute sur le port 10000
docker exec spark-iceberg netstat -tuln | findstr 10000

# Redémarrer Spark
docker-compose restart spark-iceberg

# Attendre 2 minutes puis réessayer
docker exec dbt dbt debug
```

### Problème: Jupyter ne démarre pas

**Solution**:
```powershell
# Vérifier les logs Jupyter
docker exec spark-iceberg cat /opt/spark/logs/jupyter.log

# Redémarrer le conteneur
docker-compose restart spark-iceberg
```

## Arrêt du Système

### Arrêt propre (conservation des données)

```powershell
docker-compose down
```

### Arrêt complet avec suppression des volumes

⚠️ **ATTENTION**: Cela supprimera toutes les données!

```powershell
docker-compose down -v
```

## Prochaines Étapes

Maintenant que votre système est opérationnel:

1. Consultez le [Guide de Transformation Bronze → Silver → Gold](./TRANSFORMATION_GUIDE_FR.md)
2. Explorez le [Guide dbt Avancé](./DBT_ADVANCED_FR.md)
3. Apprenez à utiliser [Spark avec Jupyter](./SPARK_JUPYTER_FR.md)

## Ressources Supplémentaires

- Documentation complète: [README_FR.md](./README_FR.md)
- Architecture du système: Voir diagrammes dans README_FR.md
- Exemples de code: Dossier `dbt_project/models/`
