# CONTRIBUTING - Guide de Contribution

Merci de votre intérêt pour contribuer au projet Data Pipeline POC BCEAO ! Ce document fournit des directives pour contribuer efficacement au projet.

## Table des matières

- [Code de conduite](#code-de-conduite)
- [Comment contribuer](#comment-contribuer)
- [Configuration de l'environnement de développement](#configuration-de-lenvironnement-de-développement)
- [Workflow de développement](#workflow-de-développement)
- [Standards de code](#standards-de-code)
- [Tests](#tests)
- [Documentation](#documentation)
- [Soumettre une Pull Request](#soumettre-une-pull-request)

## Code de conduite

Ce projet suit les principes de respect, d'inclusion et de collaboration professionnelle. Nous nous engageons à :

- Respecter toutes les contributions, quel que soit le niveau d'expérience
- Fournir des feedbacks constructifs
- Accepter les critiques de manière professionnelle
- Se concentrer sur ce qui est le mieux pour la communauté
- Faire preuve d'empathie envers les autres contributeurs

## Comment contribuer

### Types de contributions

Nous accueillons les contributions suivantes :

1. **🐛 Corrections de bugs**
   - Rapporter des bugs via GitHub Issues
   - Soumettre des corrections avec tests

2. **✨ Nouvelles fonctionnalités**
   - Proposer des features via GitHub Discussions
   - Implémenter après approbation du maintainer

3. **📚 Documentation**
   - Améliorer la documentation existante
   - Ajouter des exemples et tutoriels
   - Traduire la documentation

4. **🧪 Tests**
   - Ajouter des tests unitaires
   - Améliorer la couverture de tests
   - Créer des tests d'intégration

5. **⚡ Performance**
   - Optimiser les requêtes Spark
   - Améliorer la configuration dbt
   - Tuner les paramètres système

### Signaler un bug

Avant de créer un bug report :

1. **Vérifiez** que le bug n'a pas déjà été signalé dans [Issues](https://github.com/bceao/data-pipeline-poc/issues)
2. **Reproduisez** le bug dans un environnement propre
3. **Collectez** les logs et informations de contexte

Créez une issue avec :

```markdown
**Description du bug**
Une description claire et concise du problème.

**Étapes pour reproduire**
1. Exécuter '...'
2. Observer '...'
3. Erreur '...'

**Comportement attendu**
Ce qui devrait se passer normalement.

**Comportement actuel**
Ce qui se passe actuellement.

**Logs**
```
[Coller les logs pertinents ici]
```

**Environnement**
- OS: [ex: Windows 11, Ubuntu 22.04]
- Docker: [ex: 24.0.7]
- Version du projet: [ex: 1.1.0]

**Contexte additionnel**
Toute autre information pertinente.
```

### Proposer une nouvelle fonctionnalité

1. **Ouvrez une discussion** dans GitHub Discussions
2. **Décrivez** le use case et les bénéfices
3. **Proposez** une approche technique
4. **Attendez** les feedbacks des maintainers
5. **Créez** une issue après approbation

## Configuration de l'environnement de développement

### Prérequis

- Docker Desktop 4.0+
- Git 2.30+
- Python 3.11+ (pour scripts locaux)
- VS Code ou IDE préféré

### Setup initial

1. **Fork et clone**
   ```bash
   git clone https://github.com/VOTRE_USERNAME/data-pipeline-poc.git
   cd data-pipeline-poc
   ```

2. **Créer une branche**
   ```bash
   git checkout -b feature/ma-nouvelle-feature
   ```

3. **Télécharger les JARs AWS**
   ```bash
   mkdir -p jars
   cd jars
   curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
   curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
   cd ..
   ```

4. **Configurer environnement**
   ```bash
   cp .env.example .env
   # Éditer .env avec vos credentials de dev
   ```

5. **Démarrer les services**
   ```bash
   docker-compose up -d
   ```

6. **Vérifier le setup**
   ```bash
   docker-compose ps
   docker exec dbt bash -c "cd /usr/app/dbt && dbt debug"
   ```

## Workflow de développement

### 1. Développement local

#### Pour les modèles dbt

```bash
# Développer dans dbt_project/models/
cd dbt_project/models

# Tester un modèle spécifique
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select mon_nouveau_modele"

# Compiler pour voir le SQL généré
docker exec dbt bash -c "cd /usr/app/dbt && dbt compile --select mon_nouveau_modele"

# Vérifier le SQL compilé
cat dbt_project/target/compiled/dbt_project/models/mon_nouveau_modele.sql
```

#### Pour les scripts PySpark

```bash
# Copier le script dans le conteneur
docker cp mon_script.py spark-iceberg:/tmp/

# Exécuter avec spark-submit
docker exec spark-iceberg bash -lc "cd /opt/spark && ./bin/spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  /tmp/mon_script.py"
```

#### Pour la configuration Spark

```bash
# Modifier spark-defaults.conf
vim spark-defaults.conf

# Reconstruire l'image
docker-compose build spark-iceberg

# Redémarrer le service
docker-compose restart spark-iceberg
```

### 2. Tests

#### Tests dbt

```bash
# Exécuter tous les tests
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"

# Tester un modèle spécifique
docker exec dbt bash -c "cd /usr/app/dbt && dbt test --select mon_modele"

# Tests avec données de seed
docker exec dbt bash -c "cd /usr/app/dbt && dbt seed && dbt test"
```

#### Tests d'intégration

```bash
# Script de test end-to-end
./tests/integration/test_full_pipeline.sh

# Vérifier les données dans MinIO
docker exec mc mc ls bceao-data/lakehouse/bronze/ --recursive

# Vérifier les tables Iceberg
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SHOW TABLES IN bronze;"
```

### 3. Debugging

#### Logs Spark

```bash
# Logs du conteneur
docker logs spark-iceberg --tail=100 -f

# Spark UI
http://localhost:4040

# Logs d'une application Spark
docker exec spark-iceberg ls /opt/spark/work
docker exec spark-iceberg cat /opt/spark/work/app-*/stderr
```

#### Logs dbt

```bash
# Derniers logs dbt
docker exec dbt bash -c "cat /usr/app/dbt/logs/dbt.log | tail -n 100"

# Logs d'exécution spécifique
docker exec dbt bash -c "cat /usr/app/dbt/logs/dbt.log | grep 'ERROR'"
```

#### Shell interactif

```bash
# Spark Shell Scala
docker exec -it spark-iceberg /opt/spark/bin/spark-shell

# PySpark Shell
docker exec -it spark-iceberg /opt/spark/bin/pyspark

# Beeline SQL CLI
docker exec -it spark-iceberg beeline -u jdbc:hive2://localhost:10000
```

## Standards de code

### Python (PySpark)

- **Style**: Suivre PEP 8
- **Formatage**: Utiliser `black` (line length = 100)
- **Linting**: `pylint` avec score minimum 8.0/10
- **Type hints**: Obligatoires pour fonctions publiques

Exemple :

```python
from typing import DataFrame
from pyspark.sql import SparkSession

def create_iceberg_table(
    spark: SparkSession,
    source_path: str,
    table_name: str
) -> None:
    """
    Crée une table Iceberg depuis des fichiers Parquet.
    
    Args:
        spark: SparkSession active
        source_path: Chemin S3 des fichiers Parquet source
        table_name: Nom de la table Iceberg à créer (format: catalog.schema.table)
    
    Raises:
        ValueError: Si le chemin source n'existe pas
        RuntimeError: Si la création de table échoue
    """
    df = spark.read.parquet(source_path)
    
    df.writeTo(table_name) \
        .using("iceberg") \
        .createOrReplace()
    
    print(f"✅ Table {table_name} créée avec succès !")
```

### SQL (dbt)

- **Style**: Suivre [dbt SQL Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md)
- **Indentation**: 4 espaces
- **Mots-clés**: UPPERCASE
- **Noms**: lowercase_with_underscores

Exemple :

```sql
-- models/marts/gold_mon_nouveau_mart.sql

{{ config(
    materialized='table',
    partition_by=['annee'],
    file_format='parquet'
) }}

WITH source_data AS (
    
    SELECT
        pays,
        annee,
        trimestre,
        pib_nominal_milliards_fcfa,
        pib_reel_milliards_fcfa
    FROM {{ ref('dim_uemoa_indicators') }}
    WHERE annee >= 2010
        AND pib_nominal_milliards_fcfa > 0
    
),

calculated_metrics AS (
    
    SELECT
        pays,
        annee,
        trimestre,
        pib_nominal_milliards_fcfa,
        pib_reel_milliards_fcfa,
        (pib_nominal_milliards_fcfa - pib_reel_milliards_fcfa) AS deflateur_pib
    FROM source_data
    
)

SELECT * FROM calculated_metrics
```

### YAML (Configuration)

- **Indentation**: 2 espaces
- **Ordre**: Alphabétique pour les clés au même niveau
- **Commentaires**: Au-dessus de la clé concernée

Exemple :

```yaml
# dbt_project/models/schema.yml
version: 2

models:
  - name: mon_nouveau_modele
    description: >
      Description détaillée du modèle et de son objectif business.
      Utilise les données de...
    
    columns:
      - name: pays
        description: Code pays ISO 3166-1 alpha-3
        tests:
          - not_null
          - accepted_values:
              values: ['BEN', 'BFA', 'CIV', 'GNB', 'MLI', 'NER', 'SEN', 'TGO']
      
      - name: annee
        description: Année de référence
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 2010"
```

### Documentation

- **Docstrings**: Obligatoires pour toutes fonctions/classes Python
- **Commentaires SQL**: Expliquer la business logic, pas le SQL
- **README**: Mettre à jour si nouvelle feature impacte setup/usage
- **CHANGELOG**: Documenter tous les changements

## Tests

### Tests requis pour PR

#### 1. Tests unitaires dbt

Chaque nouveau modèle doit avoir :

```yaml
# schema.yml
- name: mon_modele
  tests:
    - dbt_utils.unique_combination_of_columns:
        combination_of_columns:
          - pays
          - annee
          - trimestre
  
  columns:
    - name: id_colonne
      tests:
        - unique
        - not_null
    
    - name: montant_colonne
      tests:
        - dbt_utils.expression_is_true:
            expression: ">= 0"
```

#### 2. Tests d'intégration

```bash
# tests/integration/test_mon_feature.sh
#!/bin/bash
set -e

echo "🧪 Test d'intégration: Ma nouvelle feature"

# 1. Créer données de test
docker exec spark-iceberg bash -c "..."

# 2. Exécuter transformation
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select mon_modele"

# 3. Vérifier résultats
RESULT=$(docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 \
  -e "SELECT COUNT(*) FROM mon_modele;" --silent=true)

if [ "$RESULT" -eq "0" ]; then
    echo "❌ Test échoué: aucune ligne générée"
    exit 1
fi

echo "✅ Test réussi: $RESULT lignes générées"
```

#### 3. Tests de performance

Pour les modèles traitant > 100k lignes :

```sql
-- Ajouter explain plan
{{ config(
    pre_hook="EXPLAIN EXTENDED SELECT * FROM {{ this }}"
) }}
```

## Documentation

### Documentation obligatoire

1. **Code Python**: Docstrings Google style
2. **Modèles dbt**: Descriptions dans `schema.yml`
3. **Configuration**: Commentaires inline
4. **README**: Mise à jour si changement d'architecture
5. **CHANGELOG**: Entrée pour chaque PR

### Exemple de documentation modèle dbt

```yaml
version: 2

models:
  - name: gold_kpi_mon_indicateur
    description: |
      # KPI Mon Indicateur
      
      ## Objectif Business
      Ce mart fournit des KPIs pour suivre [objectif métier].
      
      ## Sources de données
      - `dim_uemoa_indicators`: Indicateurs nettoyés Silver layer
      
      ## Transformations appliquées
      1. Calcul du ratio X/Y
      2. Agrégation par pays et trimestre
      3. Calcul de variation YoY
      
      ## Utilisation
      ```sql
      SELECT 
          pays,
          annee,
          mon_kpi_pct
      FROM {{ ref('gold_kpi_mon_indicateur') }}
      WHERE annee = 2024
      ORDER BY mon_kpi_pct DESC;
      ```
      
      ## Dépendances
      - Nécessite table `dim_uemoa_indicators` à jour
      - Partitionné par `annee` pour performance
      
      ## Propriétaire
      - Équipe: Analytics
      - Contact: analytics@bceao.int
    
    columns:
      - name: pays
        description: Code pays UEMOA (ISO 3166-1 alpha-3)
        
      - name: mon_kpi_pct
        description: |
          Mon KPI en pourcentage.
          Formule: (X / Y) * 100
          Valeurs typiques: 0-100%
```

## Soumettre une Pull Request

### Checklist avant soumission

- [ ] Code suit les standards de style
- [ ] Tous les tests passent (`dbt test`)
- [ ] Nouvelle fonctionnalité a des tests
- [ ] Documentation mise à jour
- [ ] CHANGELOG.md mis à jour
- [ ] Commit messages sont clairs
- [ ] Pas de credentials hardcodés
- [ ] PR description est complète

### Format du message de commit

Utiliser [Conventional Commits](https://www.conventionalcommits.org/) :

```
type(scope): description courte

Description longue optionnelle expliquant:
- Pourquoi ce changement
- Quel problème il résout
- Comment il le résout

Refs: #123
```

Types :
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage (pas de changement de code)
- `refactor`: Refactoring (pas de changement fonctionnel)
- `perf`: Amélioration de performance
- `test`: Ajout/modification de tests
- `chore`: Maintenance (deps, config, etc.)

Exemples :

```
feat(dbt): ajouter mart gold_kpi_dette_souveraine

Implémente un nouveau mart pour suivre l'évolution de la dette
souveraine des pays UEMOA avec calculs de ratios dette/PIB et
service de la dette.

Inclut:
- Modèle SQL avec partitioning par année
- Tests de qualité données (not_null, >= 0)
- Documentation schema.yml

Refs: #45
```

```
fix(spark): corriger auth S3 pour lecture Parquet

Le SparkSession n'utilisait pas correctement les credentials
MinIO, causant des erreurs 403 Forbidden.

Solution: Ajouter credentials explicites dans spark.config()
au lieu de variables d'environnement non substituées.

Fixes: #67
```

### Template de Pull Request

```markdown
## Description

Brève description du changement et de sa motivation.

## Type de changement

- [ ] 🐛 Bug fix (non-breaking change qui corrige un problème)
- [ ] ✨ Nouvelle fonctionnalité (non-breaking change qui ajoute une feature)
- [ ] 💥 Breaking change (correction ou feature causant incompatibilité)
- [ ] 📚 Documentation uniquement

## Tests effectués

Décrire les tests que vous avez exécutés :

```bash
docker exec dbt bash -c "cd /usr/app/dbt && dbt test"
# Résultats : ...
```

## Checklist

- [ ] Mon code suit les standards du projet
- [ ] J'ai effectué une self-review
- [ ] J'ai commenté les parties complexes
- [ ] J'ai mis à jour la documentation
- [ ] Mes changements ne génèrent pas de warnings
- [ ] J'ai ajouté des tests
- [ ] Tous les tests (nouveaux et existants) passent
- [ ] J'ai mis à jour CHANGELOG.md

## Screenshots (si applicable)

[Ajouter screenshots de Spark UI, MinIO console, etc.]

## Notes additionnelles

Toute information supplémentaire pour les reviewers.
```

## Review Process

1. **Automated checks**: CI/CD vérifie linting, tests
2. **Code review**: Minimum 1 approbation de maintainer
3. **Testing**: Les reviewers testent la PR localement
4. **Documentation review**: Vérification de la doc
5. **Merge**: Squash and merge vers `main`

## Besoin d'aide ?

- 💬 **Discussions**: Posez des questions dans [GitHub Discussions](https://github.com/bceao/data-pipeline-poc/discussions)
- 🐛 **Issues**: Signalez des bugs dans [GitHub Issues](https://github.com/bceao/data-pipeline-poc/issues)
- 📧 **Email**: Contactez l'équipe à data-engineering@bceao.int

Merci de contribuer au projet Data Pipeline POC BCEAO ! 🚀
