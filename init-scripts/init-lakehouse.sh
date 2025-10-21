#!/bin/bash
# Script d'initialisation automatique du Data Lakehouse
# Ce script crée tous les namespaces et tables nécessaires

set -e

echo "=== Initialisation du Data Lakehouse ==="

# Attendre que le service Iceberg REST soit prêt
echo "Attente du service Iceberg REST..."
sleep 10

# Créer les namespaces
echo "Création des namespaces..."
spark-sql -e "
CREATE NAMESPACE IF NOT EXISTS bronze COMMENT 'Couche Bronze - Données brutes';
CREATE NAMESPACE IF NOT EXISTS default_silver COMMENT 'Couche Silver - Données nettoyées';
CREATE NAMESPACE IF NOT EXISTS default_gold COMMENT 'Couche Gold - Données analytiques';
"

# Créer les tables Bronze
echo "Création des tables Bronze..."
spark-sql -e "
CREATE TABLE IF NOT EXISTS bronze.raw_events (
  event_id INT,
  event_type STRING,
  user_id INT,
  event_timestamp TIMESTAMP,
  event_data STRING
) USING iceberg
COMMENT 'Événements bruts capturés du système';

CREATE TABLE IF NOT EXISTS bronze.raw_users (
  user_id INT,
  user_name STRING,
  email STRING,
  created_at TIMESTAMP
) USING iceberg
COMMENT 'Utilisateurs bruts du système';
"

# Insérer les données de test
echo "Insertion des données de test..."
spark-sql -e "
INSERT INTO bronze.raw_events VALUES 
  (1, 'login', 101, CAST('2024-01-15 10:30:00' AS TIMESTAMP), 'ip:192.168.1.1'),
  (2, 'page_view', 101, CAST('2024-01-15 10:31:00' AS TIMESTAMP), 'page:/home'),
  (3, 'logout', 101, CAST('2024-01-15 11:00:00' AS TIMESTAMP), 'duration:1800'),
  (4, 'login', 102, CAST('2024-01-15 11:15:00' AS TIMESTAMP), 'ip:192.168.1.2'),
  (5, 'purchase', 102, CAST('2024-01-15 11:20:00' AS TIMESTAMP), 'amount:49.99'),
  (6, 'page_view', 103, CAST('2024-01-15 12:00:00' AS TIMESTAMP), 'page:/products'),
  (7, 'login', 103, CAST('2024-01-15 12:05:00' AS TIMESTAMP), 'ip:192.168.1.3'),
  (8, 'purchase', 103, CAST('2024-01-15 12:10:00' AS TIMESTAMP), 'amount:99.99'),
  (9, 'logout', 102, CAST('2024-01-15 12:30:00' AS TIMESTAMP), 'duration:4500'),
  (10, 'page_view', 101, CAST('2024-01-15 13:00:00' AS TIMESTAMP), 'page:/account');

INSERT INTO bronze.raw_users VALUES 
  (101, 'Alice Smith', 'alice@example.com', CAST('2024-01-01 09:00:00' AS TIMESTAMP)),
  (102, 'Bob Johnson', 'bob@example.com', CAST('2024-01-02 10:00:00' AS TIMESTAMP)),
  (103, 'Carol White', 'carol@example.com', CAST('2024-01-03 11:00:00' AS TIMESTAMP));
"

# Créer les tables Silver
echo "Création des tables Silver..."
spark-sql -e "
CREATE TABLE IF NOT EXISTS stg_events 
USING iceberg 
COMMENT 'Événements nettoyés et standardisés'
AS SELECT 
  event_id, 
  event_type, 
  user_id, 
  event_timestamp, 
  event_data 
FROM bronze.raw_events;

CREATE TABLE IF NOT EXISTS stg_users 
USING iceberg 
COMMENT 'Utilisateurs nettoyés et standardisés'
AS SELECT 
  user_id, 
  user_name, 
  email, 
  created_at 
FROM bronze.raw_users;
"

# Créer la table Gold
echo "Création des tables Gold..."
spark-sql -e "
CREATE TABLE IF NOT EXISTS fct_events_enriched 
USING iceberg 
COMMENT 'Événements enrichis avec informations utilisateurs'
AS SELECT 
  e.event_id,
  e.event_type,
  e.user_id,
  u.user_name,
  u.email,
  e.event_timestamp,
  e.event_data
FROM stg_events e
LEFT JOIN stg_users u ON e.user_id = u.user_id;
"

# Afficher un résumé
echo ""
echo "=== Résumé de l'initialisation ==="
spark-sql -e "
SELECT 'Bronze: raw_events' AS table_name, COUNT(*) AS row_count FROM bronze.raw_events
UNION ALL
SELECT 'Bronze: raw_users', COUNT(*) FROM bronze.raw_users
UNION ALL
SELECT 'Silver: stg_events', COUNT(*) FROM stg_events
UNION ALL
SELECT 'Silver: stg_users', COUNT(*) FROM stg_users
UNION ALL
SELECT 'Gold: fct_events_enriched', COUNT(*) FROM fct_events_enriched;
"

echo ""
echo "=== Initialisation terminée avec succès ! ==="
