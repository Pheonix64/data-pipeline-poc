# Copie des Datamarts UEMOA vers TimescaleDB

## 📋 Vue d'ensemble

Ce guide explique comment copier les 5 datamarts Gold de l'UEMOA depuis Apache Iceberg vers TimescaleDB pour des analyses opérationnelles.

### Tables concernées
1. `gold_mart_uemoa_monetary_dashboard` - Tableau de bord monétaire
2. `gold_mart_uemoa_public_finance` - Finances publiques
3. `gold_mart_uemoa_external_trade` - Commerce extérieur
4. `gold_mart_uemoa_external_stability` - Stabilité externe
5. `gold_kpi_uemoa_growth_yoy` - Indicateurs de croissance YoY

## 🚀 Procédure d'installation

### Étape 1 : Installer le driver PostgreSQL JDBC

```powershell
.\setup_postgresql_driver.ps1
```

Ce script :
- Télécharge le driver PostgreSQL JDBC (postgresql-42.6.0.jar)
- Le copie dans le conteneur Spark (`/opt/spark/jars/`)
- Vérifie l'installation

### Étape 2 : Copier les données vers TimescaleDB

```powershell
.\run_copy_uemoa.ps1
```

Ce script :
- Vérifie que Docker et les conteneurs sont actifs
- Copie le script Python dans le conteneur Spark
- Exécute la copie avec `spark-submit`
- Affiche un résumé des tables créées

## 🔧 Configuration

### Connexion PostgreSQL
- **Host** : `timescaledb` (dans le réseau Docker)
- **Port** : `5432` (communication interne Docker) / `5433` (accès externe)
  - ⚠️ **Important** : Utiliser le port **5432** pour les connexions depuis les conteneurs Docker
  - Le port 5433 est pour les connexions depuis l'hôte Windows
- **Database** : `monetary_policy_dm`
- **User** : `postgres`
- **Password** : `postgres`
- **Schema** : `public`

### Architecture technique
- **Source** : Apache Iceberg namespace `default_gold` (sur MinIO S3)
  - ⚠️ **Important** : Les tables sont dans le namespace **`default_gold`**, pas `gold`
- **Moteur** : Apache Spark 3.5.5 avec PySpark
- **Driver JDBC** : postgresql-42.6.0.jar
- **Protocole** : JDBC pour la copie
- **Cible** : TimescaleDB (PostgreSQL 15)
- **Mode** : Overwrite (écrasement complet)
- **Réseau Docker** : data-pipeline-net

## 📊 Vérification des données

### Se connecter à TimescaleDB

```powershell
docker exec -it timescaledb psql -U postgres -d monetary_policy_dm
```

### Lister les tables UEMOA

```sql
SELECT table_name, 
       pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'gold_%'
ORDER BY table_name;
```

### Compter les lignes par table

```sql
SELECT 
    'gold_mart_uemoa_monetary_dashboard' as table, 
    COUNT(*) as rows 
FROM gold_mart_uemoa_monetary_dashboard
UNION ALL
SELECT 'gold_mart_uemoa_public_finance', COUNT(*) 
FROM gold_mart_uemoa_public_finance
UNION ALL
SELECT 'gold_mart_uemoa_external_trade', COUNT(*) 
FROM gold_mart_uemoa_external_trade
UNION ALL
SELECT 'gold_mart_uemoa_external_stability', COUNT(*) 
FROM gold_mart_uemoa_external_stability
UNION ALL
SELECT 'gold_kpi_uemoa_growth_yoy', COUNT(*) 
FROM gold_kpi_uemoa_growth_yoy;
```

### Exemples de requêtes analytiques

```sql
-- Tableau de bord monétaire récent
SELECT pays, periode, masse_monetaire_m2, taux_directeur
FROM gold_mart_uemoa_monetary_dashboard
ORDER BY periode DESC
LIMIT 10;

-- Évolution des finances publiques par pays
SELECT pays, 
       AVG(solde_budgetaire) as solde_moyen,
       AVG(dette_publique_pib) as dette_moyenne
FROM gold_mart_uemoa_public_finance
GROUP BY pays
ORDER BY dette_moyenne DESC;

-- Balance commerciale par pays
SELECT pays,
       SUM(exportations) as total_exports,
       SUM(importations) as total_imports,
       SUM(exportations - importations) as solde_commercial
FROM gold_mart_uemoa_external_trade
GROUP BY pays
ORDER BY solde_commercial DESC;

-- Indicateurs de stabilité externe
SELECT pays, periode,
       reserves_en_mois_imports,
       ratio_service_dette
FROM gold_mart_uemoa_external_stability
ORDER BY periode DESC, pays;

-- Croissance YoY par indicateur
SELECT pays, indicateur,
       AVG(croissance_yoy) as croissance_moyenne
FROM gold_kpi_uemoa_growth_yoy
GROUP BY pays, indicateur
ORDER BY pays, indicateur;
```

## 🔄 Synchronisation incrémentale

Pour une synchronisation régulière, planifiez le script avec Windows Task Scheduler :

```powershell
# Créer une tâche planifiée (exemple quotidien à 2h du matin)
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\Users\siissaka\Desktop\Stage BCEAO\data-pipeline-poc\run_copy_uemoa.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

Register-ScheduledTask -TaskName "CopieUemoaTimescaleDB" `
    -Action $action -Trigger $trigger `
    -Description "Copie quotidienne des datamarts UEMOA vers TimescaleDB"
```

## 🐛 Dépannage

### Erreur : Driver PostgreSQL non trouvé

```
java.sql.SQLException: No suitable driver found
```

**Solution** : Exécutez `.\setup_postgresql_driver.ps1` pour installer le driver JDBC.

**Vérification** :
```powershell
docker exec spark-iceberg ls -lh /opt/spark/jars/postgresql-42.6.0.jar
```

### Erreur : Connexion refusée

```
Connection refused: timescaledb:5432
```

**Solutions possibles** :

1. Vérifiez que TimescaleDB est démarré :
```powershell
docker ps | Select-String timescaledb
docker-compose up -d timescaledb
```

2. ⚠️ **Vérifiez le port utilisé** : 
   - Pour connexions internes Docker : utiliser port **5432**
   - Pour connexions depuis Windows : utiliser port **5433**

3. Testez la connexion :
```powershell
docker exec timescaledb psql -U postgres -c "SELECT version();"
```

### Erreur : Table Iceberg non trouvée

```
Table or view not found: gold.gold_mart_uemoa_* ou default_gold.gold_mart_uemoa_*
```

**Solutions** :

1. Vérifiez le namespace Iceberg utilisé :
```powershell
docker exec spark-iceberg python3 -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
spark.sql('SHOW NAMESPACES').show()
"
```

2. Vérifiez que les tables existent dans `default_gold` :
```powershell
docker exec spark-iceberg python3 -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
spark.sql('SHOW TABLES IN default_gold').show(100, False)
"
```

3. ⚠️ **Important** : Les tables UEMOA sont dans le namespace **`default_gold`**, pas `gold`

4. Si les tables n'existent pas, exécutez les transformations dbt :
```powershell
cd dbt_project
dbt run --models gold_mart_uemoa_* gold_kpi_uemoa_*
```

### Erreur : Mémoire insuffisante

```
OutOfMemoryError: Java heap space
```

**Solution** : Augmentez la mémoire allouée à Spark dans `docker-compose.yml` :
```yaml
spark-iceberg:
  environment:
    - SPARK_DRIVER_MEMORY=4g
    - SPARK_EXECUTOR_MEMORY=4g
```

Puis redémarrez le conteneur :
```powershell
docker-compose restart spark-iceberg
```

### Les scripts PowerShell ne s'exécutent pas

**Erreur** :
```
impossible de charger le fichier ... car l'exécution de scripts est désactivée
```

**Solution** :
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📁 Fichiers du projet

| Fichier | Description | Lignes | Statut |
|---------|-------------|--------|--------|
| `setup_postgresql_driver.ps1` | Installation du driver JDBC PostgreSQL | ~90 | ✅ Testé |
| `copy_uemoa_to_timescale.py` | Script PySpark pour la copie des données | 281 | ✅ Testé |
| `run_copy_uemoa.ps1` | Script PowerShell d'exécution | ~90 | ✅ Testé |
| `COPY_UEMOA_TO_TIMESCALE.md` | Ce fichier (documentation) | ~250 | ✅ À jour |
| `VERIFICATION_COPIE_UEMOA.md` | Rapport de vérification et corrections | - | ✅ Complet |

## ✅ Résultats de Test

### Test réussi - Novembre 2024

**Configuration** :
- 5 tables UEMOA
- 95 lignes totales
- Temps d'exécution : ~6.6 secondes

**Résultats** :
| Table | Lignes Source | Lignes Cible | Statut |
|-------|---------------|--------------|--------|
| gold_mart_uemoa_monetary_dashboard | 20 | 20 | ✅ |
| gold_mart_uemoa_public_finance | 15 | 15 | ✅ |
| gold_mart_uemoa_external_trade | 20 | 20 | ✅ |
| gold_mart_uemoa_external_stability | 20 | 20 | ✅ |
| gold_kpi_uemoa_growth_yoy | 20 | 20 | ✅ |
| **TOTAL** | **95** | **95** | **✅ 100%** |

**Corrections appliquées** :
1. ✅ Port JDBC : 5433 → 5432 (communication interne Docker)
2. ✅ Namespace Iceberg : `gold` → `default_gold`
3. ✅ Gestion d'erreurs PowerShell améliorée

**Vérification dans TimescaleDB** :
```sql
-- Toutes les tables ont été créées avec succès
SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'gold_%'
ORDER BY table_name;

-- Résultat : 5 tables, ~8192 bytes chacune
```

## 🔍 Points Importants à Retenir

### Configuration Critique

1. **Port PostgreSQL** :
   - ❌ Incorrect : `5433` (port externe)
   - ✅ Correct : `5432` (port interne Docker)

2. **Namespace Iceberg** :
   - ❌ Incorrect : `gold`
   - ✅ Correct : `default_gold`

3. **Driver JDBC** :
   - Doit être installé dans `/opt/spark/jars/` du conteneur Spark
   - Fichier : `postgresql-42.6.0.jar`

### Commandes de Vérification Utiles

```powershell
# Vérifier que Docker fonctionne
docker info

# Vérifier les conteneurs actifs
docker ps

# Vérifier le driver JDBC
docker exec spark-iceberg ls -lh /opt/spark/jars/postgresql-42.6.0.jar

# Vérifier les tables Iceberg
docker exec spark-iceberg python3 -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
spark.sql('SHOW TABLES IN default_gold').show(100, False)
"

# Vérifier les tables PostgreSQL
docker exec timescaledb psql -U postgres -d monetary_policy_dm -c "\dt"

# Compter les lignes dans PostgreSQL
docker exec timescaledb psql -U postgres -d monetary_policy_dm -c "
SELECT 
    'gold_mart_uemoa_monetary_dashboard' as table, COUNT(*) FROM gold_mart_uemoa_monetary_dashboard
UNION ALL SELECT 'gold_mart_uemoa_public_finance', COUNT(*) FROM gold_mart_uemoa_public_finance
UNION ALL SELECT 'gold_mart_uemoa_external_trade', COUNT(*) FROM gold_mart_uemoa_external_trade
UNION ALL SELECT 'gold_mart_uemoa_external_stability', COUNT(*) FROM gold_mart_uemoa_external_stability
UNION ALL SELECT 'gold_kpi_uemoa_growth_yoy', COUNT(*) FROM gold_kpi_uemoa_growth_yoy;
"
```

## 📚 Références

- [Documentation TimescaleDB](https://docs.timescale.com/)
- [Guide de transformation UEMOA](./UEMOA_TRANSFORMATION_GUIDE_FR.md)
- [Architecture du projet](./ARCHITECTURE.md)
- [PostgreSQL JDBC Driver](https://jdbc.postgresql.org/)
