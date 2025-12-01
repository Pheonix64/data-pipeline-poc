# ✅ Checklist de Validation - Data Pipeline POC BCEAO

**Objectif** : Valider que l'installation complète du Data Pipeline est fonctionnelle

**Durée estimée** : 15-20 minutes

---

## 📋 Pr\u00e9requis

Avant de commencer la validation, assurez-vous que :

- [ ] Docker Desktop est install\u00e9 et en cours d'ex\u00e9cution
- [ ] Docker Compose est disponible (v2.0+)
- [ ] Au moins 8GB de RAM disponible
- [ ] Au moins 50GB d'espace disque libre
- [ ] Fichier `.env` cr\u00e9\u00e9 avec les credentials

---

## 1️⃣ V\u00e9rification des Services Docker

### \u00c9tape 1.1 : V\u00e9rifier que tous les conteneurs sont d\u00e9marr\u00e9s

```powershell
docker-compose ps
```

**R\u00e9sultat attendu** : Tous les services affichent `Up` ou `Healthy`

```
NAME                STATUS
minio              Up (healthy)
iceberg-rest       Up
spark-iceberg      Up (healthy)
dbt                Up (healthy)
timescaledb        Up
chromadb           Up
```

- [ ] ✅ 6/6 services en cours d'ex\u00e9cution

### \u00c9tape 1.2 : V\u00e9rifier les health checks

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**R\u00e9sultat attendu** : Health checks affichent `healthy`

- [ ] ✅ MinIO : healthy
- [ ] ✅ Spark-Iceberg : healthy
- [ ] ✅ dbt : healthy

### \u00c9tape 1.3 : V\u00e9rifier l'absence d'erreurs dans les logs

```powershell
# V\u00e9rifier les logs Spark
docker-compose logs spark-iceberg | Select-String "ERROR"

# V\u00e9rifier les logs dbt
docker-compose logs dbt | Select-String "ERROR"
```

**R\u00e9sultat attendu** : Aucune erreur critique

- [ ] ✅ Pas d'erreur ERROR dans les logs

---

## 2️⃣ V\u00e9rification des Points d'Acc\u00e8s Web

### \u00c9tape 2.1 : Tester MinIO Console

**URL** : http://localhost:9001

**Test** :
```powershell
curl -I http://localhost:9001
```

**R\u00e9sultat attendu** : HTTP 200 OK ou 403 Forbidden

- [ ] ✅ MinIO Console accessible
- [ ] ✅ Login r\u00e9ussi avec admin / SuperSecret123
- [ ] ✅ Buckets `bronze`, `silver`, `gold`, `lakehouse` pr\u00e9sents

### \u00c9tape 2.2 : Tester Jupyter Notebook

**URL** : http://localhost:8888

**Test** :
```powershell
curl -I http://localhost:8888
```

**R\u00e9sultat attendu** : HTTP 200 OK

- [ ] ✅ Jupyter accessible sans mot de passe
- [ ] ✅ Interface JupyterLab s'affiche

### \u00c9tape 2.3 : Tester Spark UI

**URL** : http://localhost:4040

**Test** :
```powershell
curl -I http://localhost:4040
```

**R\u00e9sultat attendu** : HTTP 200 OK

- [ ] ✅ Spark UI accessible
- [ ] ✅ ThriftServer visible dans l'interface

### \u00c9tape 2.4 : Tester Iceberg REST Catalog

**URL** : http://localhost:8181

**Test** :
```powershell
curl http://localhost:8181/v1/config
```

**R\u00e9sultat attendu** : R\u00e9ponse JSON

- [ ] ✅ Iceberg REST API r\u00e9pond

---

## 3️⃣ V\u00e9rification de la Couche Bronze

### \u00c9tape 3.1 : V\u00e9rifier les namespaces Iceberg

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW NAMESPACES;"
```

**R\u00e9sultat attendu** :
```
bronze
default
default_silver
default_gold
```

- [ ] ✅ Namespaces cr\u00e9\u00e9s correctement

### \u00c9tape 3.2 : V\u00e9rifier les tables Bronze

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN bronze;"
```

**R\u00e9sultat attendu** :
```
raw_events
raw_users
indicateurs_economiques_uemoa (si UEMOA configur\u00e9)
```

- [ ] ✅ Tables Bronze pr\u00e9sentes

### \u00c9tape 3.3 : Compter les donn\u00e9es de test

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.raw_events;"
```

**R\u00e9sultat attendu** : `20` ou plus

- [ ] ✅ Donn\u00e9es de test pr\u00e9sentes dans Bronze

---

## 4️⃣ V\u00e9rification des Transformations dbt

### \u00c9tape 4.1 : Tester la connexion dbt

```powershell
docker exec dbt bash -c "cd /usr/app/dbt && dbt debug"
```

**R\u00e9sultat attendu** :
```
All checks passed!
```

- [ ] ✅ dbt connect\u00e9 \u00e0 Spark Thrift Server

### \u00c9tape 4.2 : Ex\u00e9cuter les transformations dbt

```powershell
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"
```

**R\u00e9sultat attendu** :
```
Done. PASS=X WARN=0 ERROR=0 SKIP=0 TOTAL=X
```

- [ ] ✅ Toutes les transformations dbt r\u00e9ussies (0 ERROR)

### \u00c9tape 4.3 : Ex\u00e9cuter les tests dbt

```powershell
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"
```

**R\u00e9sultat attendu** : Tous les tests passent

- [ ] ✅ Tests dbt r\u00e9ussis

---

## 5️⃣ V\u00e9rification de la Couche Silver

### \u00c9tape 5.1 : V\u00e9rifier les tables Silver

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN default_silver;"
```

**R\u00e9sultat attendu** :
```
stg_events
stg_users
dim_uemoa_indicators (si UEMOA configur\u00e9)
```

- [ ] ✅ Tables Silver cr\u00e9\u00e9es

### \u00c9tape 5.2 : V\u00e9rifier les donn\u00e9es Silver

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM default_silver.stg_events;"
```

**R\u00e9sultat attendu** : Nombre > 0

- [ ] ✅ Donn\u00e9es transform\u00e9es pr\u00e9sentes

### \u00c9tape 5.3 : V\u00e9rifier la qualit\u00e9 des donn\u00e9es

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
SELECT 
  COUNT(*) as total_rows,
  COUNT(DISTINCT event_id) as unique_events,
  COUNT(event_id) - COUNT(DISTINCT event_id) as duplicates
FROM default_silver.stg_events;"
```

- [ ] ✅ Pas de valeurs NULL dans colonnes critiques
- [ ] ✅ Pas de doublons (ou doublons g\u00e9r\u00e9s)

---

## 6️⃣ V\u00e9rification de la Couche Gold

### \u00c9tape 6.1 : V\u00e9rifier les tables Gold

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN default_gold;"
```

**R\u00e9sultat attendu** :
```
fct_events_enriched
gold_mart_uemoa_* (si UEMOA configur\u00e9)
```

- [ ] ✅ Tables Gold cr\u00e9\u00e9es

### \u00c9tape 6.2 : Compter les donn\u00e9es Gold

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM default_gold.fct_events_enriched;"
```

**R\u00e9sultat attendu** : Nombre > 0

- [ ] ✅ Donn\u00e9es analytics pr\u00e9sentes

### \u00c9tape 6.3 : V\u00e9rifier l'enrichissement

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
SELECT event_id, user_name, user_email 
FROM default_gold.fct_events_enriched 
LIMIT 5;"
```

**R\u00e9sultat attendu** : Colonnes `user_name` et `user_email` remplies

- [ ] ✅ Jointures r\u00e9ussies (donn\u00e9es enrichies)

---

## 7️⃣ V\u00e9rification UEMOA (Si Applicable)

### \u00c9tape 7.1 : V\u00e9rifier la table Bronze UEMOA

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM bronze.indicateurs_economiques_uemoa;"
```

**R\u00e9sultat attendu** : Nombre > 0

- [ ] ✅ Donn\u00e9es UEMOA dans Bronze

### \u00c9tape 7.2 : V\u00e9rifier la dimension Silver UEMOA

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SELECT COUNT(*) FROM default_silver.dim_uemoa_indicators;"
```

**R\u00e9sultat attendu** : Nombre > 0

- [ ] ✅ Dimension UEMOA nettoy\u00e9e

### \u00c9tape 7.3 : V\u00e9rifier les marts Gold UEMOA

```powershell
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW TABLES IN default_gold LIKE 'gold_%uemoa%';"
```

**R\u00e9sultat attendu** : 5 tables
```
gold_kpi_uemoa_growth_yoy
gold_mart_uemoa_external_stability
gold_mart_uemoa_external_trade
gold_mart_uemoa_monetary_dashboard
gold_mart_uemoa_public_finance
```

- [ ] ✅ 5 marts UEMOA cr\u00e9\u00e9s

### \u00c9tape 7.4 : V\u00e9rifier la copie vers TimescaleDB (optionnel)

```powershell
docker exec timescaledb psql -U postgres -d monetary_policy_dm -c "\dt"
```

**R\u00e9sultat attendu** : Tables `gold_mart_uemoa_*` pr\u00e9sentes

- [ ] ✅ Donn\u00e9es copi\u00e9es dans TimescaleDB

---

## 8️⃣ V\u00e9rification Jupyter & PySpark

### \u00c9tape 8.1 : Cr\u00e9er un notebook de test

1. Ouvrir http://localhost:8888
2. Cr\u00e9er un nouveau notebook Python 3
3. Ex\u00e9cuter le code suivant :

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("ValidationTest") \
    .getOrCreate()

# Tester connexion Iceberg
spark.sql("SHOW NAMESPACES").show()

# Lire des donn\u00e9es
df = spark.sql("SELECT * FROM bronze.raw_events LIMIT 10")
df.show()

print("✅ Spark et Iceberg fonctionnent correctement !")
```

**R\u00e9sultat attendu** : Code ex\u00e9cut\u00e9 sans erreur

- [ ] ✅ Spark session cr\u00e9\u00e9e
- [ ] ✅ Namespaces affich\u00e9s
- [ ] ✅ Donn\u00e9es lues depuis Iceberg

---

## 9️⃣ V\u00e9rification du Stockage MinIO

### \u00c9tape 9.1 : V\u00e9rifier les buckets

```powershell
docker exec mc mc ls bceao-data/
```

**R\u00e9sultat attendu** :
```
bronze/
silver/
gold/
lakehouse/
```

- [ ] ✅ Tous les buckets pr\u00e9sents

### \u00c9tape 9.2 : V\u00e9rifier les m\u00e9tadonn\u00e9es Iceberg

```powershell
docker exec mc mc ls bceao-data/lakehouse/bronze/
```

**R\u00e9sultat attendu** : Dossiers pour chaque table Bronze

- [ ] ✅ M\u00e9tadonn\u00e9es Iceberg pr\u00e9sentes

---

## 🔟 V\u00e9rification TimescaleDB

### \u00c9tape 10.1 : Tester la connexion

```powershell
docker exec timescaledb psql -U postgres -c "SELECT version();"
```

**R\u00e9sultat attendu** : Version PostgreSQL affich\u00e9e

- [ ] ✅ TimescaleDB accessible

### \u00c9tape 10.2 : V\u00e9rifier la base de donn\u00e9es

```powershell
docker exec timescaledb psql -U postgres -c "\l"
```

**R\u00e9sultat attendu** : Base `monetary_policy_dm` pr\u00e9sente

- [ ] ✅ Base de donn\u00e9es cr\u00e9\u00e9e

---

## 📊 Rapport de Validation

### R\u00e9sum\u00e9 des V\u00e9rifications

| Cat\u00e9gorie | \u00c9l\u00e9ments V\u00e9rifi\u00e9s | Statut |
|-----------|------------------|--------|
| **Services Docker** | 6 services | ☐ |
| **Points d'acc\u00e8s web** | 4 URLs | ☐ |
| **Couche Bronze** | Tables et donn\u00e9es | ☐ |
| **Transformations dbt** | Run et tests | ☐ |
| **Couche Silver** | Tables et qualit\u00e9 | ☐ |
| **Couche Gold** | Marts analytics | ☐ |
| **UEMOA** | 5 marts + TimescaleDB | ☐ |
| **Jupyter** | PySpark fonctionnel | ☐ |
| **MinIO** | Buckets et m\u00e9tadonn\u00e9es | ☐ |
| **TimescaleDB** | Connexion et base | ☐ |

### Score de Validation

**Total** : _____ / 10 cat\u00e9gories r\u00e9ussies

- **10/10** : ✅ Installation parfaite !
- **8-9/10** : 🟢 Installation fonctionnelle, quelques ajustements mineurs
- **6-7/10** : 🟡 Installation partielle, corrections n\u00e9cessaires
- **< 6/10** : 🔴 Probl\u00e8mes critiques, consulter [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 🐛 En Cas de Probl\u00e8me

Si une ou plusieurs v\u00e9rifications \u00e9chouent :

1. **Consulter** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Guide de d\u00e9pannage complet
2. **V\u00e9rifier** les logs : `docker-compose logs [service-name]`
3. **Red\u00e9marrer** le service concern\u00e9 : `docker-compose restart [service-name]`
4. **Reconstruire** si n\u00e9cessaire : `docker-compose down && docker-compose build --no-cache && docker-compose up -d`

---

## ✅ Validation R\u00e9ussie !

Si toutes les v\u00e9rifications sont ✅ :

**F\u00e9licitations !** Votre Data Pipeline POC BCEAO est **100% op\u00e9rationnel**.

### Prochaines \u00c9tapes

1. **Explorer** la documentation : [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)
2. **Cr\u00e9er** vos premiers modèles dbt personnalis\u00e9s
3. **Int\u00e9grer** vos donn\u00e9es r\u00e9elles via Airbyte
4. **D\u00e9velopper** des dashboards sur les marts Gold

---

**Auteur** : GitHub Copilot  
**Derni\u00e8re mise \u00e0 jour** : 1er d\u00e9cembre 2025  
**Version** : 1.0.0
