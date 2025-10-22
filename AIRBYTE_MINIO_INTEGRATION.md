# Guide: Connecter Airbyte à MinIO comme Destination

Ce guide explique comment configurer Airbyte (existant sur http://localhost:8000/) pour utiliser MinIO de ce projet comme destination de données.

---

## Table des Matières

1. [Prérequis](#prérequis)
2. [Option A: Réseau Docker Partagé (Recommandé)](#option-a-réseau-docker-partagé)
3. [Option B: Accès via Host Network](#option-b-accès-via-host-network)
4. [Configuration dans Airbyte](#configuration-dans-airbyte)
5. [Test de Connexion](#test-de-connexion)
6. [Exemples de Pipelines](#exemples-de-pipelines)

---

## Prérequis

✅ Airbyte déjà installé et accessible sur http://localhost:8000/  
✅ MinIO opérationnel dans ce projet (http://localhost:9001)  
✅ Identifiants MinIO disponibles dans le fichier `.env`

---

## Option A: Réseau Docker Partagé (Recommandé)

Cette option permet à Airbyte de communiquer directement avec MinIO via le réseau Docker interne.

### Étape 1: Identifier le Conteneur Airbyte

```powershell
# Trouver les conteneurs Airbyte
docker ps | Select-String "airbyte"
```

**Résultat attendu**: Vous devriez voir plusieurs conteneurs (airbyte-server, airbyte-worker, airbyte-webapp, etc.)

### Étape 2: Connecter le Conteneur Airbyte Worker au Réseau

Le **worker** est le conteneur qui exécute les synchronisations.

```powershell
# Connecter airbyte-worker au réseau du data pipeline
docker network connect data-pipeline-poc_data-pipeline-net airbyte-worker

# Vérifier la connexion
docker inspect airbyte-worker | Select-String "data-pipeline"
```

### Étape 3: Vérifier l'Accès depuis Airbyte Worker

```powershell
# Tester la connexion depuis le worker
docker exec airbyte-worker curl -I http://minio:9000
```

**Résultat attendu**: Réponse HTTP 403 ou 200 (ce qui confirme que MinIO est accessible)

### Étape 4: Configuration dans Airbyte UI

Accédez à http://localhost:8000/ et créez une nouvelle destination S3:

**Paramètres de connexion**:

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **Destination Name** | `MinIO Data Pipeline` | Nom de votre choix |
| **S3 Bucket Name** | `bronze` ou `silver` ou `gold` | Bucket cible |
| **S3 Bucket Path** | `airbyte/` | Préfixe pour organiser les données |
| **S3 Bucket Region** | `us-east-1` | Région MinIO |
| **S3 Endpoint** | `http://minio:9000` | ⚠️ Important: Utiliser le nom du conteneur |
| **Access Key ID** | Valeur de `MINIO_ROOT_USER` | Depuis votre .env |
| **Secret Access Key** | Valeur de `MINIO_ROOT_PASSWORD` | Depuis votre .env |
| **S3 Path Format** | `${NAMESPACE}/${STREAM_NAME}/${YEAR}_${MONTH}_${DAY}_${EPOCH}_` | Format recommandé |
| **File Format** | `Parquet` ou `JSON` | Parquet recommandé pour Iceberg |

**Exemple de configuration**:
```yaml
S3 Endpoint: http://minio:9000
Access Key ID: admin
Secret Access Key: password123
Bucket Name: bronze
Bucket Path: airbyte/raw/
```

### Étape 5: Tester la Connexion

Dans Airbyte, cliquez sur **"Test"** pour valider la connexion.

**Résultat attendu**: ✅ "Connection test succeeded"

---

## Option B: Accès via Host Network

Si l'Option A ne fonctionne pas, utilisez l'adresse de l'hôte.

### Étape 1: Trouver l'IP de l'Hôte

```powershell
# Sur Windows
ipconfig | Select-String "IPv4"
```

Ou utilisez l'adresse spéciale Docker:
- **Windows/Mac**: `host.docker.internal`
- **Linux**: `172.17.0.1` (généralement)

### Étape 2: Configuration dans Airbyte

**Paramètres de connexion**:

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| **S3 Endpoint** | `http://host.docker.internal:9000` | Pour Windows/Mac |
| **S3 Endpoint** | `http://172.17.0.1:9000` | Pour Linux |
| **Access Key ID** | Valeur de `MINIO_ROOT_USER` | Depuis votre .env |
| **Secret Access Key** | Valeur de `MINIO_ROOT_PASSWORD` | Depuis votre .env |
| **S3 Bucket Name** | `bronze` | Ou autre bucket |

---

## Configuration dans Airbyte (Détaillée)

### Créer une Nouvelle Destination S3/MinIO

1. **Accédez à Airbyte**: http://localhost:8000/

2. **Allez dans "Destinations"**: Menu latéral → Destinations → + New destination

3. **Sélectionnez "S3"** comme type de destination

4. **Remplissez le formulaire**:

#### Configuration Basique

```yaml
Destination name: MinIO - Bronze Layer
S3 Bucket Name: bronze
S3 Bucket Path: airbyte/
S3 Bucket Region: us-east-1
```

#### Configuration de l'Endpoint (CRITIQUE)

```yaml
# Option A (Réseau Docker)
S3 Endpoint: http://minio:9000

# Option B (Host Network)
S3 Endpoint: http://host.docker.internal:9000
```

#### Authentification

```yaml
Access Key ID: admin           # Depuis .env: MINIO_ROOT_USER
Secret Access Key: password123 # Depuis .env: MINIO_ROOT_PASSWORD
```

#### Format de Fichier (Recommandations)

**Pour intégration avec Spark/Iceberg**:
```yaml
Output Format: Parquet
Compression: GZIP
```

**Pour flexibilité**:
```yaml
Output Format: JSONL (JSON Lines)
Compression: GZIP
```

#### Pattern de Chemin

```yaml
S3 Path Format: ${NAMESPACE}/${STREAM_NAME}/${YEAR}_${MONTH}_${DAY}_${EPOCH}_
```

**Exemple de chemin généré**:
```
s3://bronze/airbyte/public/users/2025_10_21_1729508400_0.parquet
```

5. **Testez la connexion**: Cliquez sur "Test" en bas du formulaire

6. **Sauvegardez**: Cliquez sur "Set up destination"

---

## Test de Connexion

### Vérification Manuelle depuis Airbyte Worker

```powershell
# Entrer dans le conteneur worker
docker exec -it airbyte-worker /bin/bash

# Tester la connectivité MinIO
curl -I http://minio:9000

# Tester avec les credentials
apt-get update && apt-get install -y awscli
aws configure set aws_access_key_id admin
aws configure set aws_secret_access_key password123
aws --endpoint-url http://minio:9000 s3 ls
```

### Vérification depuis MinIO

Après une synchronisation Airbyte réussie:

1. **Via MinIO Console**: http://localhost:9001
   - Naviguer vers le bucket `bronze`
   - Vérifier le dossier `airbyte/`

2. **Via Spark**:
```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
  CREATE EXTERNAL TABLE IF NOT EXISTS airbyte_test (
    id INT,
    name STRING
  )
  STORED AS PARQUET
  LOCATION 's3a://bronze/airbyte/';
  
  SELECT * FROM airbyte_test LIMIT 10;
"
```

---

## Exemples de Pipelines Airbyte → MinIO

### Exemple 1: Base de Données PostgreSQL → Bronze (MinIO)

**Source**: PostgreSQL  
**Destination**: MinIO (bucket `bronze`)  
**Format**: Parquet

**Configuration de la Source**:
```yaml
Host: postgres-source.example.com
Port: 5432
Database: production
User: readonly_user
Password: ********
Schemas: public, sales
```

**Configuration de la Destination**:
```yaml
S3 Bucket: bronze
S3 Path: airbyte/postgres/
Format: Parquet
Compression: Snappy
```

**Chemin résultant**:
```
s3://bronze/airbyte/postgres/public/users/2025_10_21_*.parquet
s3://bronze/airbyte/postgres/sales/orders/2025_10_21_*.parquet
```

### Exemple 2: API REST → MinIO → Spark Transformation

**Pipeline complet**:
```
API REST (Airbyte Source)
    ↓ [Sync]
MinIO Bronze (s3://bronze/airbyte/api_data/)
    ↓ [dbt transformation]
MinIO Silver (s3://silver/cleaned_api_data/)
    ↓ [dbt aggregation]
MinIO Gold (s3://gold/api_metrics/)
```

**Après synchronisation Airbyte**, créer une table Iceberg:

```sql
-- Dans Spark/Beeline
CREATE TABLE bronze.api_data
USING iceberg
LOCATION 's3a://bronze/airbyte/api_data/'
TBLPROPERTIES (
  'format-version'='2',
  'write.format.default'='parquet'
);

-- Ensuite, transformer avec dbt
```

### Exemple 3: Pipeline Temps Réel

**Configuration pour streaming**:
```yaml
Sync Schedule: Every 15 minutes
Normalization: Basic normalization
Incremental Sync: Enabled
Cursor Field: updated_at
```

---

## Architecture: Airbyte + Data Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCES DE DONNÉES                        │
│  • Bases de données (PostgreSQL, MySQL, etc.)               │
│  • APIs (REST, GraphQL)                                      │
│  • SaaS (Salesforce, HubSpot, etc.)                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      AIRBYTE                                 │
│              (http://localhost:8000)                         │
│  • Extraction des données                                    │
│  • Transformations basiques                                  │
│  • Synchronisation programmée                                │
└──────────────────┬──────────────────────────────────────────┘
                   │ Écriture Parquet/JSON
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              MINIO - COUCHE BRONZE                           │
│           s3://bronze/airbyte/*                              │
│  • Données brutes depuis Airbyte                             │
│  • Format: Parquet (recommandé)                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│            SPARK + DBT - TRANSFORMATIONS                     │
│  • Lecture depuis Bronze                                     │
│  • Nettoyage et validation                                   │
│  • Enrichissement et agrégation                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│         MINIO - COUCHES SILVER & GOLD                        │
│  • Silver: Données nettoyées                                 │
│  • Gold: Métriques et analyses                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Configuration Avancée

### Sécurité: Utiliser HTTPS avec MinIO

Si vous configurez HTTPS pour MinIO en production:

```yaml
S3 Endpoint: https://minio:9000
# Airbyte validera automatiquement les certificats
```

### Performance: Optimisation des Écritures

```yaml
S3 File Buffer Size: 10MB      # Taille du buffer mémoire
S3 Part Size: 5MB               # Taille des parties multipart
Compression: SNAPPY             # Plus rapide que GZIP
```

### Organisation: Structure de Buckets Recommandée

```
bronze/
  ├── airbyte/              # Données depuis Airbyte
  │   ├── postgres/         # Par source
  │   ├── salesforce/
  │   └── api_data/
  └── manual/               # Chargements manuels

silver/
  ├── cleaned/              # Données nettoyées
  └── validated/            # Données validées

gold/
  ├── metrics/              # Métriques calculées
  └── reports/              # Données pour reporting
```

---

## Dépannage

### Problème: "Connection refused" depuis Airbyte

**Cause**: Le worker Airbyte n'est pas sur le bon réseau.

**Solution**:
```powershell
# Vérifier les réseaux du worker
docker inspect airbyte-worker | Select-String "Networks"

# Connecter au réseau si nécessaire
docker network connect data-pipeline-poc_data-pipeline-net airbyte-worker

# Redémarrer le worker
docker restart airbyte-worker
```

### Problème: "Access Denied" depuis Airbyte

**Cause**: Identifiants MinIO incorrects.

**Solution**:
1. Vérifier les identifiants dans `.env`
2. Tester manuellement:
```powershell
docker exec airbyte-worker curl -u admin:password123 http://minio:9000
```

### Problème: "Bucket does not exist"

**Cause**: Le bucket n'existe pas dans MinIO.

**Solution**:
```powershell
# Lister les buckets
docker exec minio mc ls minio

# Créer le bucket si nécessaire
docker exec minio mc mb minio/bronze
```

### Problème: Fichiers créés mais pas visibles dans Spark

**Cause**: Spark n'a pas rechargé le cache de métadonnées.

**Solution**:
```sql
-- Rafraîchir les métadonnées
REFRESH TABLE bronze.airbyte_data;

-- Ou recréer la table
DROP TABLE IF EXISTS bronze.airbyte_data;
CREATE TABLE bronze.airbyte_data USING iceberg LOCATION 's3a://bronze/airbyte/';
```

---

## Commandes Utiles

### Vérifier la Connectivité Réseau

```powershell
# Depuis airbyte-worker vers minio
docker exec airbyte-worker ping -c 3 minio

# Tester le port MinIO
docker exec airbyte-worker nc -zv minio 9000
```

### Lister les Fichiers Créés par Airbyte

```powershell
# Via MinIO CLI
docker exec spark-iceberg mc ls bceao-data/bronze/airbyte/

# Via Spark
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
  SHOW TABLES IN bronze;
"
```

### Surveiller les Synchronisations

```powershell
# Logs du worker Airbyte
docker logs -f airbyte-worker

# Logs MinIO
docker logs -f minio
```

---

## Checklist de Configuration

Avant de commencer:

- [ ] Airbyte accessible sur http://localhost:8000/
- [ ] MinIO accessible sur http://localhost:9001/
- [ ] Identifiants MinIO disponibles (`.env`)
- [ ] Buckets MinIO créés (`bronze`, `silver`, `gold`)
- [ ] Réseau Docker identifié (`data-pipeline-poc_data-pipeline-net`)

Configuration Airbyte:

- [ ] Conteneur `airbyte-worker` connecté au réseau
- [ ] Destination S3/MinIO créée dans Airbyte
- [ ] Endpoint configuré: `http://minio:9000`
- [ ] Identifiants testés
- [ ] Test de connexion réussi
- [ ] Premier pipeline créé et testé

Vérification:

- [ ] Fichiers visibles dans MinIO Console
- [ ] Données lisibles depuis Spark/Jupyter
- [ ] Pipeline de transformation fonctionnel

---

## Résumé des Paramètres Clés

| Paramètre | Valeur pour ce Projet |
|-----------|----------------------|
| **S3 Endpoint** | `http://minio:9000` (réseau Docker) |
| **Access Key** | Valeur de `MINIO_ROOT_USER` dans `.env` |
| **Secret Key** | Valeur de `MINIO_ROOT_PASSWORD` dans `.env` |
| **Bucket Bronze** | `bronze` |
| **Région** | `us-east-1` |
| **Format Recommandé** | `Parquet` avec compression `Snappy` |
| **Réseau Docker** | `data-pipeline-poc_data-pipeline-net` |

---

## Prochaines Étapes

Après avoir connecté Airbyte à MinIO:

1. **Créer votre premier pipeline**: Source → MinIO (Bronze)
2. **Créer des tables Iceberg**: Pour lire les données Airbyte dans Spark
3. **Développer des transformations dbt**: Bronze → Silver → Gold
4. **Automatiser**: Configurer les synchronisations programmées
5. **Monitorer**: Surveiller les pipelines et l'utilisation du stockage

---

**Besoin d'aide?** Consultez:
- [Documentation Airbyte](https://docs.airbyte.com/)
- [Documentation MinIO](https://min.io/docs/)
- [README_FR.md](./README_FR.md) - Documentation du projet
