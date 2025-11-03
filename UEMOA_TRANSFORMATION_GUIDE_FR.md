# Guide de Transformation des Données UEMOA

## 📋 Vue d'Ensemble

Ce guide détaille les transformations spécifiques appliquées aux **indicateurs économiques de l'UEMOA** (Union Économique et Monétaire Ouest-Africaine) dans le Data Lakehouse.

---

## 🎯 Architecture des Données UEMOA

```
BRONZE                          SILVER                      GOLD
──────                          ──────                      ────
indicateurs_economiques_uemoa → dim_uemoa_indicators    →  gold_mart_uemoa_monetary_dashboard
(Données brutes Parquet)        (Données nettoyées)        gold_mart_uemoa_public_finance
                                                            gold_mart_uemoa_external_trade
                                                            gold_mart_uemoa_external_stability
                                                            gold_kpi_uemoa_growth_yoy
```

---

## 📊 Données Sources (Bronze)

### Table: `bronze.indicateurs_economiques_uemoa`

**Source**: Fichiers Parquet stockés dans MinIO
**Localisation**: `s3://lakehouse/bronze/indicateurs_economiques_uemoa/`

#### Création de la Table Bronze

**Script Python** : `create_uemoa_table.py`

```python
from pyspark.sql import SparkSession

# Créer la session Spark avec configuration S3
spark = SparkSession.builder \
    .appName("CreateUemoaTable") \
    .config("spark.hadoop.fs.s3a.access.key", "admin") \
    .config("spark.hadoop.fs.s3a.secret.key", "SuperSecret123") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Lire les fichiers Parquet depuis MinIO
df = spark.read.parquet("s3a://lakehouse/bronze/indicateurs_economiques_uemoa/")

# Écrire comme table Iceberg
df.writeTo("bronze.indicateurs_economiques_uemoa") \
    .using("iceberg") \
    .createOrReplace()

print("Table bronze.indicateurs_economiques_uemoa créée avec succès!")
```

**Exécution**:
```powershell
# Copier le script dans le conteneur
docker cp create_uemoa_table.py spark-iceberg:/tmp/

# Exécuter le script
docker exec spark-iceberg spark-submit /tmp/create_uemoa_table.py
```

#### Colonnes Disponibles

| Catégorie | Colonnes |
|-----------|----------|
| **Temporel** | `date` |
| **PIB & Croissance** | `pib_nominal_milliards_fcfa`, `taux_croissance_reel_pib_pct`, `poids_secteur_primaire_pct`, `poids_secteur_secondaire_pct`, `poids_secteur_tertiaire_pct` |
| **Inflation** | `taux_inflation_moyen_annuel_ipc_pct` |
| **Finances Publiques** | `recettes_fiscales`, `recettes_fiscales_pct_pib`, `depenses_totales_et_prets_nets`, `solde_budgetaire_global_avec_dons`, `solde_budgetaire_global_hors_dons` |
| **Dette Publique** | `encours_de_la_dette`, `encours_de_la_dette_pct_pib` |
| **Commerce Extérieur** | `exportations_biens_fob`, `importations_biens_fob`, `balance_des_biens`, `compte_transactions_courantes`, `balance_courante_sur_pib_pct` |
| **Agrégats Monétaires** | `agregats_monnaie_masse_monetaire_m2`, `taux_couverture_emission_monetaire` |

---

## 🥈 Couche Silver - Données Nettoyées

### Table: `silver.dim_uemoa_indicators`

**Objectif**: Créer une source de vérité propre pour tous les modèles Gold

**Fichier**: `dbt_project/models/silver/dim_uemoa_indicators.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='silver'
  )
}}

-- Source de vérité propre pour tous les modèles Gold
-- Applique les premières transformations et nettoyages
SELECT
    date,
    pib_nominal_milliards_fcfa,
    poids_secteur_primaire_pct,
    poids_secteur_secondaire_pct,
    poids_secteur_tertiaire_pct,
    taux_croissance_reel_pib_pct,
    taux_inflation_moyen_annuel_ipc_pct,
    recettes_fiscales,
    recettes_fiscales_pct_pib,
    depenses_totales_et_prets_nets,
    solde_budgetaire_global_avec_dons,
    solde_budgetaire_global_hors_dons,
    encours_de_la_dette,
    encours_de_la_dette_pct_pib,
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    compte_transactions_courantes,
    balance_courante_sur_pib_pct,
    agregats_monnaie_masse_monetaire_m2,
    taux_couverture_emission_monetaire
FROM
    {{ source('bronze', 'indicateurs_economiques_uemoa') }}
WHERE
    pib_nominal_milliards_fcfa IS NOT NULL
```

**Transformations Appliquées**:
- ✅ Filtrage des enregistrements sans PIB
- ✅ Sélection des colonnes pertinentes
- ✅ Standardisation des noms de colonnes

**Exécution**:
```powershell
docker exec dbt dbt run --select dim_uemoa_indicators
```

---

## 🥇 Couche Gold - Marts Analytiques

### 1. 💰 Tableau de Bord Monétaire

**Table**: `gold.gold_mart_uemoa_monetary_dashboard`

**Objectif**: Pilotage de la politique monétaire de la BCEAO

**Fichier**: `dbt_project/models/gold/gold_mart_uemoa_monetary_dashboard.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Tableau de bord de pilotage monétaire
-- Calcule la croissance des agrégats et les ratios clés
SELECT
    date,
    pib_nominal_milliards_fcfa,
    agregats_monnaie_masse_monetaire_m2,
    taux_inflation_moyen_annuel_ipc_pct,
    
    -- Croissance Année-sur-Année (YoY) de la masse monétaire
    (agregats_monnaie_masse_monetaire_m2 - LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date))
        / LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date) * 100 
        as m2_croissance_yoy_pct,

    -- Vélocité de la monnaie (V) : vitesse de circulation
    -- V = PIB Nominal / M2
    pib_nominal_milliards_fcfa / agregats_monnaie_masse_monetaire_m2 
        as velocite_monnaie,

    -- Taux de couverture de l'émission monétaire
    taux_couverture_emission_monetaire

FROM
    {{ ref('dim_uemoa_indicators') }}
WHERE
    agregats_monnaie_masse_monetaire_m2 IS NOT NULL
ORDER BY
    date DESC
```

**KPIs Calculés**:
- 📈 Croissance YoY de M2
- 💨 Vélocité de la monnaie
- 🛡️ Taux de couverture de l'émission

**Cas d'Usage**:
- Surveillance de la masse monétaire
- Détection de l'inflation monétaire
- Analyse de la politique monétaire

---

### 2. 💼 Finances Publiques

**Table**: `gold.gold_mart_uemoa_public_finance`

**Objectif**: Analyse des finances publiques de l'UEMOA

**Fichier**: `dbt_project/models/gold/gold_mart_uemoa_public_finance.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Data mart focalisé sur les finances publiques
SELECT
    date,
    pib_nominal_milliards_fcfa,
    
    -- Recettes
    recettes_fiscales,
    recettes_fiscales_pct_pib,
    
    -- Dépenses
    depenses_totales_et_prets_nets,
    
    -- Soldes budgétaires
    solde_budgetaire_global_avec_dons,
    solde_budgetaire_global_hors_dons,
    (solde_budgetaire_global_avec_dons / pib_nominal_milliards_fcfa) * 100 
        as solde_budgetaire_avec_dons_pct_pib,
    
    -- Dette publique
    encours_de_la_dette,
    encours_de_la_dette_pct_pib

FROM
    {{ ref('dim_uemoa_indicators') }}
WHERE
    EXTRACT(YEAR FROM date) >= 2010
ORDER BY
    date DESC
```

**KPIs Calculés**:
- 💵 Recettes fiscales / PIB
- 💸 Solde budgétaire / PIB
- 📊 Dette publique / PIB

**Cas d'Usage**:
- Analyse de la soutenabilité budgétaire
- Surveillance des critères de convergence UEMOA
- Reporting au Ministère des Finances

---

### 3. 🌍 Commerce Extérieur

**Table**: `gold.gold_mart_uemoa_external_trade`

**Objectif**: Analyse du commerce extérieur et balance des paiements

**Fichier**: `dbt_project/models/gold/gold_mart_uemoa_external_trade.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Data mart commerce extérieur et balance des paiements
SELECT
    date,
    pib_nominal_milliards_fcfa,
    
    -- Balance commerciale
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    (balance_des_biens / pib_nominal_milliards_fcfa) * 100 
        as balance_des_biens_pct_pib,

    -- Balance courante
    compte_transactions_courantes,
    balance_courante_sur_pib_pct

FROM
    {{ ref('dim_uemoa_indicators') }}
ORDER BY
    date DESC
```

**KPIs Calculés**:
- 📦 Balance commerciale / PIB
- 💱 Balance courante / PIB
- 📈 Évolution des exportations/importations

**Cas d'Usage**:
- Surveillance de la compétitivité externe
- Analyse des termes de l'échange
- Détection des déséquilibres externes

---

### 4. 🛡️ Stabilité Externe

**Table**: `gold.gold_mart_uemoa_external_stability`

**Objectif**: Indicateurs de soutenabilité externe

**Fichier**: `dbt_project/models/gold/gold_mart_uemoa_external_stability.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Indicateurs de soutenabilité externe de l'UEMOA
SELECT
    date,
    
    -- Commerce extérieur
    exportations_biens_fob,
    importations_biens_fob,
    balance_des_biens,
    compte_transactions_courantes,
    balance_courante_sur_pib_pct,
    
    -- Importations mensuelles moyennes
    (importations_biens_fob / 12) as importations_mensuelles_moyennes,
    
    -- Taux de couverture des importations par les exportations
    CASE 
        WHEN importations_biens_fob != 0 
        THEN (exportations_biens_fob / importations_biens_fob) * 100
        ELSE NULL
    END as taux_couverture_importations_pct,
    
    -- Degré d'ouverture commerciale
    -- (Exportations + Importations) / PIB * 100
    CASE 
        WHEN pib_nominal_milliards_fcfa != 0 
        THEN ((exportations_biens_fob + importations_biens_fob) / pib_nominal_milliards_fcfa) * 100
        ELSE NULL
    END as degre_ouverture_commerciale_pct,

    -- Taux de couverture de l'émission monétaire
    taux_couverture_emission_monetaire,
    
    -- Dette externe
    encours_de_la_dette,
    encours_de_la_dette_pct_pib

FROM
    {{ ref('dim_uemoa_indicators') }}
WHERE
    importations_biens_fob IS NOT NULL 
    AND importations_biens_fob != 0
ORDER BY
    date DESC
```

**KPIs Calculés**:
- 📊 Taux de couverture des importations
- 🌐 Degré d'ouverture commerciale
- 💰 Taux de couverture de l'émission
- 📉 Soutenabilité de la dette

**Cas d'Usage**:
- Évaluation de la vulnérabilité externe
- Surveillance des réserves de change
- Analyse de crise potentielle

---

### 5. 📈 Croissance Année-sur-Année (YoY)

**Table**: `gold.gold_kpi_uemoa_growth_yoy`

**Objectif**: Calcul des taux de croissance YoY pour tous les KPIs

**Fichier**: `dbt_project/models/gold/gold_kpi_uemoa_growth_yoy.sql`

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold'
  )
}}

-- Calcule la croissance Année-sur-Année (YoY) des KPIs
SELECT
    date,
    pib_nominal_milliards_fcfa,
    taux_croissance_reel_pib_pct,
    taux_inflation_moyen_annuel_ipc_pct,
    
    -- Croissance YoY du PIB nominal
    LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date) 
        as pib_nominal_annee_precedente,
    (pib_nominal_milliards_fcfa - LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date)) 
        / LAG(pib_nominal_milliards_fcfa, 1) OVER (ORDER BY date) * 100 
        as pib_nominal_croissance_yoy_pct,

    -- Croissance YoY des recettes fiscales
    recettes_fiscales,
    (recettes_fiscales - LAG(recettes_fiscales, 1) OVER (ORDER BY date))
        / LAG(recettes_fiscales, 1) OVER (ORDER BY date) * 100 
        as recettes_fiscales_croissance_yoy_pct,

    -- Croissance YoY de M2
    agregats_monnaie_masse_monetaire_m2,
    (agregats_monnaie_masse_monetaire_m2 - LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date))
        / LAG(agregats_monnaie_masse_monetaire_m2, 1) OVER (ORDER BY date) * 100 
        as m2_croissance_yoy_pct

FROM
    {{ ref('dim_uemoa_indicators') }}
ORDER BY
    date DESC
```

**KPIs Calculés**:
- 📊 Croissance YoY du PIB nominal
- 💵 Croissance YoY des recettes fiscales
- 💰 Croissance YoY de la masse monétaire M2

**Cas d'Usage**:
- Analyse des tendances macroéconomiques
- Graphiques de performance temporelle
- Comparaisons inter-annuelles

---

## 🚀 Exécution des Transformations

### Créer la Table Bronze

```powershell
# Méthode 1: Via script Python
docker cp create_uemoa_table.py spark-iceberg:/tmp/
docker exec spark-iceberg spark-submit /tmp/create_uemoa_table.py

# Méthode 2: Via Jupyter Notebook
# Accédez à http://localhost:8888
# Ouvrez create_uemoa_iceberg_table.ipynb et exécutez les cellules
```

### Transformer Bronze → Silver

```powershell
# Exécuter le modèle Silver
docker exec dbt dbt run --select dim_uemoa_indicators

# Vérifier la table créée
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) FROM silver.dim_uemoa_indicators;"
```

### Transformer Silver → Gold

```powershell
# Exécuter tous les modèles Gold
docker exec dbt dbt run --select gold_mart_uemoa_monetary_dashboard
docker exec dbt dbt run --select gold_mart_uemoa_public_finance
docker exec dbt dbt run --select gold_mart_uemoa_external_trade
docker exec dbt dbt run --select gold_mart_uemoa_external_stability
docker exec dbt dbt run --select gold_kpi_uemoa_growth_yoy

# Ou exécuter tous les modèles Gold d'un coup
docker exec dbt dbt run --select gold_*
```

### Vérification

```powershell
# Lister toutes les tables Gold UEMOA
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW TABLES IN gold LIKE 'gold_%uemoa%';"

# Compter les lignes
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
SELECT 'gold_mart_uemoa_monetary_dashboard' as table_name, COUNT(*) as count 
FROM gold.gold_mart_uemoa_monetary_dashboard
UNION ALL
SELECT 'gold_mart_uemoa_public_finance', COUNT(*) 
FROM gold.gold_mart_uemoa_public_finance
UNION ALL
SELECT 'gold_mart_uemoa_external_trade', COUNT(*) 
FROM gold.gold_mart_uemoa_external_trade
UNION ALL
SELECT 'gold_mart_uemoa_external_stability', COUNT(*) 
FROM gold.gold_mart_uemoa_external_stability
UNION ALL
SELECT 'gold_kpi_uemoa_growth_yoy', COUNT(*) 
FROM gold.gold_kpi_uemoa_growth_yoy;
"
```

---

## 📊 Visualisation des Données UEMOA

### Via Jupyter Notebook

```python
from pyspark.sql import SparkSession
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

spark = SparkSession.builder.appName("UemoaAnalysis").getOrCreate()

# Lire les données Gold
df_monetary = spark.table("gold.gold_mart_uemoa_monetary_dashboard").toPandas()
df_finance = spark.table("gold.gold_mart_uemoa_public_finance").toPandas()
df_trade = spark.table("gold.gold_mart_uemoa_external_trade").toPandas()

# Convertir les dates
df_monetary['date'] = pd.to_datetime(df_monetary['date'])
df_finance['date'] = pd.to_datetime(df_finance['date'])
df_trade['date'] = pd.to_datetime(df_trade['date'])

# Créer des visualisations
fig, axes = plt.subplots(2, 2, figsize=(16, 12))
fig.suptitle('Tableau de Bord Économique UEMOA', fontsize=16, fontweight='bold')

# 1. Évolution du PIB
ax1 = axes[0, 0]
ax1.plot(df_monetary['date'], df_monetary['pib_nominal_milliards_fcfa'], 
         marker='o', color='blue', linewidth=2)
ax1.set_title('Évolution du PIB Nominal (Milliards FCFA)')
ax1.set_xlabel('Date')
ax1.set_ylabel('PIB (Milliards FCFA)')
ax1.grid(True, alpha=0.3)

# 2. Masse Monétaire M2
ax2 = axes[0, 1]
ax2.plot(df_monetary['date'], df_monetary['agregats_monnaie_masse_monetaire_m2'], 
         marker='s', color='green', linewidth=2)
ax2.set_title('Masse Monétaire M2')
ax2.set_xlabel('Date')
ax2.set_ylabel('M2')
ax2.grid(True, alpha=0.3)

# 3. Balance Commerciale
ax3 = axes[1, 0]
ax3.plot(df_trade['date'], df_trade['exportations_biens_fob'], 
         marker='o', label='Exportations', color='blue', linewidth=2)
ax3.plot(df_trade['date'], df_trade['importations_biens_fob'], 
         marker='s', label='Importations', color='red', linewidth=2)
ax3.set_title('Commerce Extérieur')
ax3.set_xlabel('Date')
ax3.set_ylabel('Montant (FOB)')
ax3.legend()
ax3.grid(True, alpha=0.3)

# 4. Dette Publique / PIB
ax4 = axes[1, 1]
ax4.plot(df_finance['date'], df_finance['encours_de_la_dette_pct_pib'], 
         marker='o', color='orange', linewidth=2)
ax4.axhline(y=70, color='red', linestyle='--', label='Seuil 70%')
ax4.set_title('Dette Publique (% du PIB)')
ax4.set_xlabel('Date')
ax4.set_ylabel('Dette / PIB (%)')
ax4.legend()
ax4.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# Statistiques récapitulatives
print("\n" + "="*60)
print("STATISTIQUES UEMOA - DONNÉES LES PLUS RÉCENTES")
print("="*60)

latest_monetary = df_monetary.iloc[0]
latest_finance = df_finance.iloc[0]
latest_trade = df_trade.iloc[0]

print(f"\n📊 PIB Nominal: {latest_monetary['pib_nominal_milliards_fcfa']:,.0f} Mds FCFA")
print(f"💰 Masse Monétaire M2: {latest_monetary['agregats_monnaie_masse_monetaire_m2']:,.0f}")
print(f"📈 Inflation: {latest_monetary['taux_inflation_moyen_annuel_ipc_pct']:.2f}%")
print(f"💵 Recettes Fiscales/PIB: {latest_finance['recettes_fiscales_pct_pib']:.2f}%")
print(f"📊 Dette/PIB: {latest_finance['encours_de_la_dette_pct_pib']:.2f}%")
print(f"🌍 Balance Commerciale/PIB: {latest_trade['balance_des_biens_pct_pib']:.2f}%")
```

### Requêtes Analytiques SQL

```sql
-- Top 5 années avec la plus forte croissance du PIB
SELECT 
    EXTRACT(YEAR FROM date) as annee,
    AVG(taux_croissance_reel_pib_pct) as croissance_moyenne
FROM silver.dim_uemoa_indicators
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY croissance_moyenne DESC
LIMIT 5;

-- Évolution de la dette publique sur 10 ans
SELECT 
    EXTRACT(YEAR FROM date) as annee,
    AVG(encours_de_la_dette_pct_pib) as dette_pct_pib_moyenne
FROM gold.gold_mart_uemoa_public_finance
WHERE EXTRACT(YEAR FROM date) >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY annee;

-- Corrélation inflation vs croissance monétaire
SELECT 
    date,
    taux_inflation_moyen_annuel_ipc_pct,
    m2_croissance_yoy_pct,
    (m2_croissance_yoy_pct - taux_inflation_moyen_annuel_ipc_pct) as ecart
FROM gold.gold_kpi_uemoa_growth_yoy
WHERE m2_croissance_yoy_pct IS NOT NULL
ORDER BY date DESC;
```

---

## 🎯 Critères de Convergence UEMOA

Les critères de convergence peuvent être surveillés via ces requêtes :

```sql
-- Critère 1: Ratio du solde budgétaire de base sur PIB ≥ -3%
SELECT 
    date,
    solde_budgetaire_avec_dons_pct_pib,
    CASE 
        WHEN solde_budgetaire_avec_dons_pct_pib >= -3 THEN 'RESPECTÉ'
        ELSE 'NON RESPECTÉ'
    END as critere_solde_budgetaire
FROM gold.gold_mart_uemoa_public_finance
ORDER BY date DESC;

-- Critère 2: Taux d'inflation annuel ≤ 3%
SELECT 
    date,
    taux_inflation_moyen_annuel_ipc_pct,
    CASE 
        WHEN taux_inflation_moyen_annuel_ipc_pct <= 3 THEN 'RESPECTÉ'
        ELSE 'NON RESPECTÉ'
    END as critere_inflation
FROM silver.dim_uemoa_indicators
ORDER BY date DESC;

-- Critère 3: Encours de la dette / PIB ≤ 70%
SELECT 
    date,
    encours_de_la_dette_pct_pib,
    CASE 
        WHEN encours_de_la_dette_pct_pib <= 70 THEN 'RESPECTÉ'
        ELSE 'NON RESPECTÉ'
    END as critere_dette
FROM gold.gold_mart_uemoa_public_finance
ORDER BY date DESC;

-- Tableau de bord complet des critères
SELECT 
    f.date,
    CASE WHEN f.solde_budgetaire_avec_dons_pct_pib >= -3 THEN '✓' ELSE '✗' END as solde_budgetaire,
    CASE WHEN i.taux_inflation_moyen_annuel_ipc_pct <= 3 THEN '✓' ELSE '✗' END as inflation,
    CASE WHEN f.encours_de_la_dette_pct_pib <= 70 THEN '✓' ELSE '✗' END as dette
FROM gold.gold_mart_uemoa_public_finance f
JOIN silver.dim_uemoa_indicators i ON f.date = i.date
ORDER BY f.date DESC
LIMIT 10;
```

---

## 📚 Documentation des Sources

### Configuration dbt

Ajoutez dans `dbt_project/models/staging/sources.yml`:

```yaml
version: 2

sources:
  - name: bronze
    description: Couche Bronze - Données brutes
    schema: bronze
    tables:
      - name: indicateurs_economiques_uemoa
        description: |
          Indicateurs économiques et financiers de l'UEMOA
          Source: Données statistiques BCEAO
        columns:
          - name: date
            description: Date de l'observation
            tests:
              - not_null
          - name: pib_nominal_milliards_fcfa
            description: PIB nominal en milliards de FCFA
            tests:
              - not_null
          - name: taux_croissance_reel_pib_pct
            description: Taux de croissance réel du PIB (%)
          - name: taux_inflation_moyen_annuel_ipc_pct
            description: Taux d'inflation moyen annuel IPC (%)
          - name: recettes_fiscales
            description: Recettes fiscales
          - name: encours_de_la_dette
            description: Encours de la dette publique
```

---

## 🔄 Workflow Complet

```powershell
# 1. Créer la table Bronze depuis les fichiers Parquet
docker exec spark-iceberg spark-submit /tmp/create_uemoa_table.py

# 2. Vérifier la table Bronze
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) FROM bronze.indicateurs_economiques_uemoa;"

# 3. Transformer Bronze → Silver
docker exec dbt dbt run --select dim_uemoa_indicators

# 4. Transformer Silver → Gold
docker exec dbt dbt run --select gold_mart_uemoa_monetary_dashboard
docker exec dbt dbt run --select gold_mart_uemoa_public_finance
docker exec dbt dbt run --select gold_mart_uemoa_external_trade
docker exec dbt dbt run --select gold_mart_uemoa_external_stability
docker exec dbt dbt run --select gold_kpi_uemoa_growth_yoy

# 5. Tester la qualité des données
docker exec dbt dbt test --select dim_uemoa_indicators

# 6. Vérifier les résultats
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "
SELECT 'Monetary Dashboard' as mart, COUNT(*) as rows FROM gold.gold_mart_uemoa_monetary_dashboard
UNION ALL
SELECT 'Public Finance', COUNT(*) FROM gold.gold_mart_uemoa_public_finance
UNION ALL
SELECT 'External Trade', COUNT(*) FROM gold.gold_mart_uemoa_external_trade
UNION ALL
SELECT 'External Stability', COUNT(*) FROM gold.gold_mart_uemoa_external_stability
UNION ALL
SELECT 'Growth YoY', COUNT(*) FROM gold.gold_kpi_uemoa_growth_yoy;
"
```

---

## 🎓 Bonnes Pratiques

### 1. Partitionnement

Pour de gros volumes de données, partitionner par année :

```sql
{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='gold',
    partition_by=['year(date)']
  )
}}
```

### 2. Incrémental

Pour mises à jour régulières :

```sql
{{
  config(
    materialized='incremental',
    file_format='iceberg',
    unique_key='date'
  )
}}

SELECT * FROM {{ ref('dim_uemoa_indicators') }}

{% if is_incremental() %}
  WHERE date > (SELECT MAX(date) FROM {{ this }})
{% endif %}
```

### 3. Documentation

Documentez chaque KPI calculé dans `schema.yml`

### 4. Tests de Qualité

```yaml
models:
  - name: dim_uemoa_indicators
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - date
```

---

## 📖 Ressources

- [Documentation BCEAO](https://www.bceao.int/)
- [Critères de Convergence UEMOA](https://www.uemoa.int/)
- [Guide de Transformation Principal](./TRANSFORMATION_GUIDE_FR.md)
- [Documentation dbt](https://docs.getdbt.com/)

---

**Dernière mise à jour**: 3 novembre 2025  
**Version**: 1.0.0
