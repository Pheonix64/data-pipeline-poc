"""
Script pour copier les datamarts Gold UEMOA vers TimescaleDB
Utilise PySpark avec JDBC pour la copie des données
"""

from pyspark.sql import SparkSession
import sys
import time

# Configuration PostgreSQL/TimescaleDB
POSTGRES_HOST = "timescaledb"
POSTGRES_PORT = "5432"  # Port interne dans le réseau Docker
POSTGRES_DB = "monetary_policy_dm"
POSTGRES_USER = "postgres"
POSTGRES_PASSWORD = "PostgresPass123"

# URL JDBC PostgreSQL
JDBC_URL = f"jdbc:postgresql://{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"

# Propriétés JDBC
JDBC_PROPERTIES = {
    "user": POSTGRES_USER,
    "password": POSTGRES_PASSWORD,
    "driver": "org.postgresql.Driver"
}

# Tables Gold UEMOA à copier
GOLD_TABLES = [
    "default_gold.gold_mart_uemoa_monetary_dashboard",
    "default_gold.gold_mart_uemoa_public_finance",
    "default_gold.gold_mart_uemoa_external_trade",
    "default_gold.gold_mart_uemoa_external_stability",
    "default_gold.gold_kpi_uemoa_growth_yoy"
]

def create_spark_session():
    """Crée une session Spark configurée pour Iceberg et PostgreSQL"""
    print("\n🔧 Création de la session Spark...")
    
    spark = SparkSession.builder \
        .appName("CopyUemoaToTimescaleDB") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.spark_catalog.type", "rest") \
        .config("spark.sql.catalog.spark_catalog.uri", "http://rest:8181") \
        .getOrCreate()
    
    print("✅ Session Spark créée avec succès\n")
    return spark

def test_postgres_connection(spark):
    """Teste la connexion à PostgreSQL"""
    print("🔍 Test de connexion à PostgreSQL...")
    
    try:
        # Tester la connexion en lisant la liste des tables
        test_query = "(SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' LIMIT 1) AS test"
        
        df_test = spark.read \
            .format("jdbc") \
            .option("url", JDBC_URL) \
            .option("dbtable", test_query) \
            .options(**JDBC_PROPERTIES) \
            .load()
        
        df_test.show(1)
        print("✅ Connexion PostgreSQL OK\n")
        return True
        
    except Exception as e:
        print(f"❌ Erreur de connexion PostgreSQL: {str(e)}\n")
        return False

def copy_table_to_postgres(spark, gold_table_name):
    """
    Copie une table Gold vers PostgreSQL/TimescaleDB
    
    Args:
        spark: Session Spark
        gold_table_name: Nom complet de la table Gold
    
    Returns:
        dict: Statistiques de la copie
    """
    # Extraire le nom de la table sans le schéma
    table_name = gold_table_name.split('.')[-1]
    
    print(f"\n{'='*70}")
    print(f"📦 Copie: {gold_table_name} → public.{table_name}")
    print(f"{'='*70}")
    
    stats = {
        "table": gold_table_name,
        "target": f"public.{table_name}",
        "success": False,
        "rows_read": 0,
        "rows_written": 0,
        "duration": 0
    }
    
    start_time = time.time()
    
    try:
        # 1. Lire depuis Gold (Iceberg)
        print(f"📖 Lecture depuis {gold_table_name}...")
        df = spark.table(gold_table_name)
        row_count = df.count()
        stats["rows_read"] = row_count
        
        print(f"   ✓ {row_count} lignes lues")
        
        # Afficher le schéma
        print(f"\n📋 Schéma de la table:")
        df.printSchema()
        
        # Afficher un aperçu des données
        print(f"\n👁️  Aperçu des données (5 premières lignes):")
        df.show(5, truncate=False)
        
        # 2. Écrire vers PostgreSQL
        print(f"\n💾 Écriture vers PostgreSQL: public.{table_name}...")
        
        df.write \
            .format("jdbc") \
            .option("url", JDBC_URL) \
            .option("dbtable", f"public.{table_name}") \
            .options(**JDBC_PROPERTIES) \
            .mode("overwrite") \
            .save()
        
        print(f"   ✓ Données écrites dans PostgreSQL")
        
        # 3. Vérification
        print(f"\n🔍 Vérification de la copie...")
        df_verify = spark.read \
            .format("jdbc") \
            .option("url", JDBC_URL) \
            .option("dbtable", f"public.{table_name}") \
            .options(**JDBC_PROPERTIES) \
            .load()
        
        verify_count = df_verify.count()
        stats["rows_written"] = verify_count
        
        print(f"   ✓ {verify_count} lignes vérifiées dans PostgreSQL")
        
        # Comparer les comptages
        if verify_count == row_count:
            stats["success"] = True
            print(f"\n✅ SUCCÈS! Table {table_name} copiée correctement")
            print(f"   • Source (Iceberg): {row_count} lignes")
            print(f"   • Cible (PostgreSQL): {verify_count} lignes")
        else:
            print(f"\n⚠️  ATTENTION! Nombre de lignes différent:")
            print(f"   • Source (Iceberg): {row_count} lignes")
            print(f"   • Cible (PostgreSQL): {verify_count} lignes")
        
    except Exception as e:
        print(f"\n❌ ERREUR lors de la copie de {gold_table_name}:")
        print(f"   {str(e)}")
        import traceback
        traceback.print_exc()
    
    finally:
        stats["duration"] = time.time() - start_time
    
    return stats

def list_postgres_tables(spark):
    """Liste les tables UEMOA dans PostgreSQL"""
    print(f"\n{'='*70}")
    print("📊 TABLES UEMOA DANS TIMESCALEDB")
    print(f"{'='*70}\n")
    
    try:
        query = """
        (SELECT 
            table_name,
            pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
         FROM information_schema.tables 
         WHERE table_schema = 'public' 
         AND table_name LIKE 'gold_%uemoa%'
         ORDER BY table_name) AS uemoa_tables
        """
        
        df_tables = spark.read \
            .format("jdbc") \
            .option("url", JDBC_URL) \
            .option("dbtable", query) \
            .options(**JDBC_PROPERTIES) \
            .load()
        
        df_tables.show(truncate=False)
        
        # Compter les lignes de chaque table
        print("\n📈 Nombre de lignes par table:\n")
        for table in GOLD_TABLES:
            table_name = table.split('.')[-1]
            try:
                df_count = spark.read \
                    .format("jdbc") \
                    .option("url", JDBC_URL) \
                    .option("dbtable", f"public.{table_name}") \
                    .options(**JDBC_PROPERTIES) \
                    .load()
                
                count = df_count.count()
                print(f"   • {table_name}: {count:,} lignes")
            except:
                print(f"   • {table_name}: Table non trouvée")
        
    except Exception as e:
        print(f"❌ Erreur lors de la liste des tables: {str(e)}")

def main():
    """Fonction principale"""
    print("\n" + "="*70)
    print("🏦 COPIE DES DATAMARTS UEMOA VERS TIMESCALEDB")
    print("="*70)
    
    print(f"\n📋 Configuration:")
    print(f"   • PostgreSQL Host: {POSTGRES_HOST}:{POSTGRES_PORT}")
    print(f"   • Database: {POSTGRES_DB}")
    print(f"   • User: {POSTGRES_USER}")
    print(f"   • Schema: public")
    print(f"   • Nombre de tables: {len(GOLD_TABLES)}")
    
    # Créer la session Spark
    spark = create_spark_session()
    
    # Tester la connexion PostgreSQL
    if not test_postgres_connection(spark):
        print("❌ Impossible de se connecter à PostgreSQL. Arrêt du script.")
        spark.stop()
        sys.exit(1)
    
    # Copier chaque table
    all_stats = []
    for table in GOLD_TABLES:
        stats = copy_table_to_postgres(spark, table)
        all_stats.append(stats)
    
    # Résumé final
    print(f"\n{'='*70}")
    print("📊 RÉSUMÉ DE LA COPIE")
    print(f"{'='*70}\n")
    
    success_count = sum(1 for s in all_stats if s["success"])
    total_rows = sum(s["rows_written"] for s in all_stats)
    total_duration = sum(s["duration"] for s in all_stats)
    
    for stats in all_stats:
        status = "✅" if stats["success"] else "❌"
        duration = f"{stats['duration']:.1f}s"
        rows = f"{stats['rows_written']:,}" if stats['rows_written'] > 0 else "0"
        print(f"{status} {stats['table']}")
        print(f"   → {stats['target']}: {rows} lignes ({duration})")
    
    print(f"\n📈 Statistiques globales:")
    print(f"   • Tables copiées avec succès: {success_count}/{len(GOLD_TABLES)}")
    print(f"   • Total de lignes copiées: {total_rows:,}")
    print(f"   • Durée totale: {total_duration:.1f}s")
    
    # Lister les tables dans PostgreSQL
    list_postgres_tables(spark)
    
    # Arrêter Spark
    print(f"\n🔚 Arrêt de la session Spark...")
    spark.stop()
    
    # Code de sortie
    if success_count == len(GOLD_TABLES):
        print(f"\n✅ TOUTES LES TABLES ONT ÉTÉ COPIÉES AVEC SUCCÈS!\n")
        sys.exit(0)
    else:
        print(f"\n⚠️  {len(GOLD_TABLES) - success_count} TABLE(S) N'ONT PAS PU ÊTRE COPIÉE(S)\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
