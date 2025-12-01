# 🚀 Bienvenue dans le Data Pipeline POC BCEAO

## 📖 Guide de Démarrage

Ce projet implémente un **Data Lakehouse moderne** pour l'analyse des indicateurs économiques de l'UEMOA avec Apache Iceberg, Spark et dbt.

**Dernière mise à jour** : 1er décembre 2025  
**Version** : 1.1.0

---

## 🎯 Par Où Commencer ?

## 🎯 Par Où Commencer ?

### 👤 Vous êtes Nouveau sur le Projet ?

1. **[README_FR.md](./README_FR.md)** ⭐ - Vue d'ensemble complète du projet
2. **[QUICKSTART_FR.md](./QUICKSTART_FR.md)** ⚡ - Installez et démarrez en 15 minutes
3. **[DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)** 📚 - Index de toute la documentation

### 🏦 Vous Travaillez sur les Données UEMOA ?

1. **[UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md)** - Transformations des indicateurs économiques
2. **[COPY_UEMOA_TO_TIMESCALE.md](./COPY_UEMOA_TO_TIMESCALE.md)** - Copie vers TimescaleDB
3. **[VERIFICATION_COPIE_UEMOA.md](./VERIFICATION_COPIE_UEMOA.md)** - Vérification de la copie

### 🔧 Vous Souhaitez Intégrer des Données ?

1. **[AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md)** - Configurer Airbyte
2. **[TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)** - Transformations Bronze → Silver → Gold
3. **[MINIO_STRUCTURE_GUIDE.md](./MINIO_STRUCTURE_GUIDE.md)** - Organisation des données

### 🐛 Vous Rencontrez un Problème ?

1. **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Guide de dépannage consolidé
2. **[FAQ.md](./FAQ.md)** - Questions fréquentes
3. **[VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md)** - Vérifier l'état du système

---

## 📊 État Actuel du Projet

### Pipeline de Données
```
✅ Bronze Layer: bronze.indicateurs_economiques_uemoa (20+ lignes)
✅ Silver Layer: default_silver.dim_uemoa_indicators (nettoyé)
✅ Gold Layer: 5 marts analytics (croissance, stabilité, commerce, monétaire, finances)
```

### Services Opérationnels
```
✅ Spark (Apache Spark 3.5 + Iceberg 1.8.1)
✅ MinIO (S3-compatible storage)
✅ Iceberg REST Catalog
✅ dbt (Data Build Tool 1.9)
✅ TimescaleDB (PostgreSQL with time-series)
✅ ChromaDB (Vector database)
```

---

## 🎓 Parcours d'Apprentissage

### Niveau Débutant (2-3 heures)
1. Lire [README_FR.md](./README_FR.md) - Comprendre l'architecture
2. Suivre [QUICKSTART_FR.md](./QUICKSTART_FR.md) - Installation et premiers tests
3. Explorer MinIO Console (http://localhost:9001) et Jupyter (http://localhost:8888)

**Objectif** : Système opérationnel et compréhension de base

### Niveau Intermédiaire (4-6 heures)
1. Lire [TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md) - Transformations dbt
2. Créer vos premiers modèles dbt personnalisés
3. Explorer [UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md)

**Objectif** : Créer des transformations personnalisées

### Niveau Avancé (1-2 jours)
1. Intégrer Airbyte : [AIRBYTE_MINIO_INTEGRATION.md](./AIRBYTE_MINIO_INTEGRATION.md)
2. Optimiser les performances (Iceberg compaction, partitioning)
3. Développer des pipelines complets end-to-end

**Objectif** : Pipeline de production complet

---

## 🎯 Commandes Essentielles

### Démarrer le Système
```powershell
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Voir les logs
docker-compose logs -f spark-iceberg
```

### Exécuter des Transformations
```powershell
# Toutes les transformations dbt
docker exec dbt bash -c "cd /usr/app/dbt && dbt run"

# Transformations UEMOA uniquement
docker exec dbt bash -c "cd /usr/app/dbt && dbt run --select gold_*uemoa*"
```

### Accéder aux Interfaces
- **MinIO Console**: http://localhost:9001 (admin / SuperSecret123)
- **Jupyter Notebook**: http://localhost:8888
- **Spark UI**: http://localhost:4040

---

## 📚 Documentation Complète

### Guides Principaux (Français)
1. **[README_FR.md](./README_FR.md)** - Documentation technique complète
2. **[QUICKSTART_FR.md](./QUICKSTART_FR.md)** - Démarrage rapide
3. **[TRANSFORMATION_GUIDE_FR.md](./TRANSFORMATION_GUIDE_FR.md)** - Guide des transformations
4. **[UEMOA_TRANSFORMATION_GUIDE_FR.md](./UEMOA_TRANSFORMATION_GUIDE_FR.md)** - Transformations UEMOA
5. **[COPY_UEMOA_TO_TIMESCALE.md](./COPY_UEMOA_TO_TIMESCALE.md)** - Intégration TimescaleDB

### Références Techniques
6. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architecture technique détaillée
7. **[VERSION_INFO.md](./VERSION_INFO.md)** - Informations de version
8. **[CHANGELOG.md](./CHANGELOG.md)** - Historique des modifications

### Support et Dépannage
9. **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Guide de dépannage
10. **[FAQ.md](./FAQ.md)** - Questions fréquentes
11. **[VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md)** - Vérification système

---

## 🔍 Besoin d'Aide ?

### Problème Courant ?
Consultez d'abord :
1. [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Solutions aux problèmes courants
2. [FAQ.md](./FAQ.md) - Questions fréquentes
3. [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md) - Vérifier l'état du système

### Questions Architecturales ?
→ [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture détaillée

### Documentation Complète ?
→ [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) - Index maître

---

## 🏆 Prochaines Étapes Recommandées

### Court Terme
1. ✅ Tester le pipeline complet avec vos données UEMOA réelles
2. ✅ Configurer Airbyte pour ingestion automatique
3. ✅ Créer des dashboards sur les marts Gold (Tableau, PowerBI)

### Moyen Terme
4. ⚠️ Implémenter validation automatisée (voir [VALIDATION_CHECKLIST.md](./VALIDATION_CHECKLIST.md))
5. ⚠️ Ajouter monitoring (Prometheus + Grafana)
6. ⚠️ Sécuriser pour production (secrets management, TLS/SSL)

### Long Terme
7. 🔄 Déployer en staging puis production
8. 🔄 Former les utilisateurs (analystes, data scientists)
9. 🔄 Étendre les use cases (nouveaux indicateurs, pays)

---

## 📞 Contact et Support

**Email**: data-engineering@bceao.int  
**Projet**: Data Pipeline POC BCEAO  
**Version**: 1.1.0  
**Date**: 1er décembre 2025

---

**✨ Bon développement avec votre Data Pipeline ! ✨**

---

*"Data is the new oil, but unlike oil, data is renewable." - Clive Humby*
