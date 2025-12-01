# 📚 Index de Documentation - Data Pipeline POC BCEAO

**Version**: 1.0.0 | **Date**: 27 octobre 2025

Bienvenue dans la documentation du **Data Pipeline POC BCEAO** ! Ce projet implémente une architecture Data Lakehouse moderne avec Apache Iceberg, Spark et dbt.

---

## 🚀 Démarrage Rapide

**Nouveau sur le projet ?** Commencez ici :

1. **[README.md](./README.md)** - Vue d'ensemble du projet (EN) ⭐
2. **[QUICKSTART_FR.md](./QUICKSTART_FR.md)** - Guide de démarrage rapide (FR) ⚡

**Temps estimé pour démarrer** : 15 minutes

---

## 📖 Documentation Principale

### Documentation Complète

| Document | Description | Langue | Niveau |
|----------|-------------|--------|---------|
| [README_FR.md](./README_FR.md) | Documentation technique complète | 🇫🇷 | Tous niveaux |
| [VERSION_INFO.md](./VERSION_INFO.md) | Informations détaillées de version | 🇫🇷 | Tous niveaux |
| [CHANGELOG.md](./CHANGELOG.md) | Journal des modifications | 🇫🇷 | Tous niveaux |

### Guides Pratiques

| Guide | Description | Temps de lecture | Niveau |
|-------|-------------|------------------|---------|
| [QUICKSTART_FR.md](./QUICKSTART_FR.md) | Installation et premier démarrage | 10 min | 🟢 Débutant |
| [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md) | Transformations Bronze/Silver/Gold avec dbt | 30 min | 🟡 Intermédiaire |
| [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md) | Transformations données économiques UEMOA | 25 min | 🟡 Intermédiaire |
| [COPY_UEMOA_TO_TIMESCALE.md](./COPY_UEMOA_TO_TIMESCALE.md) | Copie datamarts UEMOA vers TimescaleDB | 15 min | 🟡 Intermédiaire |
| [AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md) | Intégrer Airbyte avec MinIO | 20 min | 🟡 Intermédiaire |
| [MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md) | Organisation des buckets MinIO | 15 min | 🟢 Débutant |

### Rapports et Vérification

| Document | Description | Utilité |
|----------|-------------|---------|
| [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md) | État du système et vérifications | Dépannage et monitoring |
| [VERIFICATION_COPIE_UEMOA.md](./VERIFICATION_COPIE_UEMOA.md) | Vérification copie UEMOA vers TimescaleDB | Audit et corrections |

### Référence et Support

| Document | Description | Temps de lecture | Niveau |
|----------|-------------|------------------|---------|
| [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md) | Procédure complète de validation d'installation | 20 min | 🟢 Débutant |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Guide consolidé de dépannage | 30 min | 🟡 Intermédiaire |
| [FAQ.md](./FAQ.md) | Questions fréquentes et réponses rapides | 15 min | 🟢 Débutant |

---

## 🎯 Par Cas d'Usage

### Je veux...

#### 🚀 Installer et démarrer le système
→ [QUICKSTART_FR.md](./QUICKSTART_FR.md)
- Prérequis
- Installation pas à pas
- Vérification de l'installation
- Premiers tests

#### 🔄 Comprendre les transformations de données
→ [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)
- Architecture Médaillon
- Transformations Bronze → Silver
- Transformations Silver → Gold
- Exemples dbt et Spark

#### 🏦 Transformer les données UEMOA
→ [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md)
- Indicateurs économiques UEMOA
- Marts analytiques (Monétaire, Finances Publiques, Commerce Extérieur)
- KPIs et critères de convergence
- Tableaux de bord BCEAO

#### 🔄 Copier les datamarts UEMOA vers TimescaleDB
→ [COPY_UEMOA_TO_TIMESCALE.md](./COPY_UEMOA_TO_TIMESCALE.md)
- Installation du driver PostgreSQL JDBC
- Copie des 5 tables Gold UEMOA
- Configuration et vérification
- Dépannage et résolution de problèmes
- ✅ Scripts testés et validés

#### 📦 Organiser mes données dans MinIO
→ [MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md)
- Structure des buckets
- Bonnes pratiques
- Organisation par couche

#### 🔗 Connecter Airbyte au pipeline
→ [AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md)
- Configuration réseau
- Setup Airbyte
- Tests de connexion
- Exemples de pipelines

#### 🐛 Résoudre un problème
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) ⭐
- Problèmes Docker et services
- Erreurs de connexion
- Problèmes dbt, Spark, Iceberg
- Erreurs MinIO, UEMOA, TimescaleDB
- Performance et réseau

→ [FAQ.md](./FAQ.md)
- Questions fréquentes
- Réponses rapides
- Conseils pratiques

→ [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md)
- Vérification d'installation
- Tests système complet
- Scoring de validation

→ [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md)
- État actuel du système
- Logs et diagnostics

#### 📊 Comprendre l'architecture
→ [README_FR.md - Section Architecture](./README_FR.md#architecture-générale)
- Diagramme d'architecture
- Composants du système
- Flux de données

#### ⚙️ Configurer le système
→ [VERSION_INFO.md - Section Configuration](./VERSION_INFO.md#-configuration)
- Variables d'environnement
- Configuration Spark
- Configuration dbt
- Ports et services

---

## 📁 Structure de la Documentation

```
Documentation/
│
├── 🌟 ESSENTIELS (Lire en premier)
│   ├── README.md                      # Vue d'ensemble (EN)
│   ├── README_FR.md                   # Documentation complète (FR)
│   ├── QUICKSTART_FR.md               # Guide de démarrage rapide
│   └── START_HERE.md                  # Point d'entrée navigation
│
├── 📘 GUIDES PRATIQUES
│   ├── TRANSFORMATION_GUIDE_FR.md     # Transformations de données
│   ├── UEMOA_TRANSFORMATION_GUIDE_FR.md # Transformations données UEMOA ⭐
│   ├── COPY_UEMOA_TO_TIMESCALE.md     # Copie UEMOA vers TimescaleDB ⭐
│   ├── AIRBYTE_MINIO_INTEGRATION.md   # Intégration Airbyte
│   └── MINIO_STRUCTURE_GUIDE.md       # Organisation MinIO
│
├── 📋 RÉFÉRENCE
│   ├── VERSION_INFO.md                # Informations de version
│   ├── CHANGELOG.md                   # Historique des modifications
│   ├── VERIFICATION_REPORT.md         # Rapport de vérification
│   └── VERIFICATION_COPIE_UEMOA.md    # Vérification copie UEMOA
│
├── 🆘 SUPPORT ET DÉPANNAGE
│   ├── VALIDATION_CHECKLIST.md        # Checklist de validation ⭐
│   ├── TROUBLESHOOTING.md             # Guide de dépannage ⭐
│   └── FAQ.md                         # Questions fréquentes ⭐
│
└── 📚 MÉTA
    ├── DOCUMENTATION_INDEX.md         # Ce fichier
    └── AUDIT_DOCUMENTATION.md         # Audit de cohérence documentaire
```

---

## 🎓 Parcours d'Apprentissage

### Niveau 1 : Débutant (2-3 heures)
1. Lire [README_FR.md](./README_FR.md) - Vue d'ensemble
2. Suivre [QUICKSTART_FR.md](./QUICKSTART_FR.md) - Installation
3. Explorer Jupyter Notebook et MinIO Console
4. Exécuter première transformation dbt

**Objectif** : Système opérationnel et compréhension de base

### Niveau 2 : Intermédiaire (4-6 heures)
1. Lire [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)
2. Créer modèles dbt personnalisés
3. Explorer [MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md)
4. Requêtes Spark SQL avancées

**Objectif** : Créer des transformations personnalisées

### Niveau 3 : Avancé (1-2 jours)
1. Intégrer Airbyte avec [AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md)
2. Optimisation des performances Iceberg
3. Développer pipelines complets de données
4. Tests et monitoring

**Objectif** : Pipeline de production complet

---

## 🔍 Recherche Rapide

### Commandes Fréquentes

```bash
# Démarrer le système
docker-compose up -d

# Voir les logs
docker-compose logs -f spark-iceberg

# Exécuter dbt
docker exec dbt dbt run

# Requête SQL
docker exec spark-iceberg beeline -u jdbc:hive2://localhost:10000 -e "SHOW NAMESPACES;"
```

→ Plus de commandes dans [VERSION_INFO.md](./VERSION_INFO.md#-commandes-essentielles)

### Ports et URLs

| Service | URL |
|---------|-----|
| MinIO Console | http://localhost:9001 |
| Jupyter Notebook | http://localhost:8888 |
| Spark UI | http://localhost:4040 |
| Iceberg REST | http://localhost:8181 |

→ Détails complets dans [VERSION_INFO.md](./VERSION_INFO.md#ports-exposés)

---

## 🆘 Aide et Support

### Aide et Support
Consultez d'abord :
1. [FAQ.md](./FAQ.md) - Questions fréquentes et réponses rapides ⭐
2. [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Guide consolidé de dépannage ⭐
3. [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md) - Vérifier l'état du système ⭐
4. [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md) - Rapport de vérification système

### Comprendre un Message d'Erreur ?
- **dbt** : [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)
- **Spark** : Logs dans `docker-compose logs spark-iceberg`
- **MinIO** : Vérifier la console http://localhost:9001

### Questions Architecturales ?
→ [README_FR.md](./README_FR.md) - Architecture détaillée

---

## 📊 Métriques de Documentation

| Métrique | Valeur |
|----------|--------|
| Nombre de documents | 14 |
| Pages totales | ~150+ pages |
| Langues | Français, Anglais |
| Exemples de code | 150+ |
| Commandes shell | 80+ |
| Diagrammes | 3 |
| Scripts opérationnels | 3 (UEMOA → TimescaleDB) |
| Guides de support | 3 (FAQ, Troubleshooting, Validation) |

---

## 🔄 Mises à Jour

**Dernière mise à jour** : 27 octobre 2025

La documentation est mise à jour avec chaque nouvelle version du projet.
Consultez [CHANGELOG.md](./CHANGELOG.md) pour voir l'historique complet.

---

## 📝 Contribuer à la Documentation

Pour améliorer cette documentation :

1. Identifier les sections à améliorer
2. Proposer des clarifications ou exemples supplémentaires
3. Signaler les erreurs ou informations obsolètes
4. Suggérer de nouveaux guides pratiques

---

## 🌐 Ressources Externes

### Technologies Utilisées

| Technologie | Documentation Officielle |
|-------------|-------------------------|
| Apache Iceberg | https://iceberg.apache.org/ |
| Apache Spark | https://spark.apache.org/docs/latest/ |
| dbt | https://docs.getdbt.com/ |
| MinIO | https://min.io/docs/ |
| Docker | https://docs.docker.com/ |
| TimescaleDB | https://docs.timescale.com/ |
| ChromaDB | https://docs.trychroma.com/ |

### Tutoriels et Guides

- [Architecture Médaillon (Databricks)](https://www.databricks.com/fr/glossary/medallion-architecture)
- [Data Lakehouse Concept](https://www.databricks.com/fr/glossary/data-lakehouse)
- [Apache Iceberg Tutorial](https://iceberg.apache.org/docs/latest/getting-started/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)

---

## ✅ Checklist de Documentation

Utilisez cette checklist pour vous assurer d'avoir lu les documents nécessaires :

### Installation et Démarrage
- [ ] Lire README.md ou README_FR.md
- [ ] Suivre QUICKSTART_FR.md
- [ ] Vérifier l'installation avec VERIFICATION_REPORT.md

### Utilisation Quotidienne
- [ ] Comprendre les transformations (TRANSFORMATION_GUIDE_FR.md)
- [ ] Connaître l'organisation MinIO (MINIO_STRUCTURE_GUIDE.md)
- [ ] Avoir les commandes de référence (VERSION_INFO.md)

### Intégrations
- [ ] Lire AIRBYTE_MINIO_INTEGRATION.md si utilisation d'Airbyte
- [ ] Lire COPY_UEMOA_TO_TIMESCALE.md pour copie vers TimescaleDB

### Maintenance
- [ ] Consulter CHANGELOG.md pour les mises à jour
- [ ] Revoir VERIFICATION_REPORT.md périodiquement

---

**Bonne lecture ! 📚**

Pour toute question, commencez par [QUICKSTART_FR.md](./QUICKSTART_FR.md) puis consultez [README_FR.md](./README_FR.md) pour plus de détails.
