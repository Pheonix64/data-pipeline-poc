# Script PowerShell pour copier les datamarts UEMOA vers TimescaleDB
# Utilise Spark SQL avec JDBC PostgreSQL

$POSTGRES_HOST = "timescaledb"
$POSTGRES_PORT = "5433"
$POSTGRES_DB = "monetary_policy_dm"
$POSTGRES_USER = "postgres"
$POSTGRES_PASSWORD = "PostgresPass123"

$JDBC_URL = "jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

# Tables Gold UEMOA à copier
$GOLD_TABLES = @(
    "gold.gold_mart_uemoa_monetary_dashboard",
    "gold.gold_mart_uemoa_public_finance",
    "gold.gold_mart_uemoa_external_trade",
    "gold.gold_mart_uemoa_external_stability",
    "gold.gold_kpi_uemoa_growth_yoy"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Copie des Datamarts UEMOA vers TimescaleDB" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Configuration PostgreSQL:" -ForegroundColor Yellow
Write-Host "  Host: $POSTGRES_HOST"
Write-Host "  Port: $POSTGRES_PORT"
Write-Host "  Database: $POSTGRES_DB"
Write-Host "  User: $POSTGRES_USER`n"

# Copier chaque table
foreach ($goldTable in $GOLD_TABLES) {
    $tableName = $goldTable.Split('.')[-1]
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Copie: $goldTable -> public.$tableName" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
    # Commande Spark SQL pour copier via JDBC
    $sparkSql = @"
SELECT * FROM $goldTable
"@
    
    # Exécuter via spark-submit avec un script Python temporaire
    $pythonScript = @"
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('CopyToTimescale').getOrCreate()

# Lire depuis Gold
df = spark.sql('$sparkSql')
print(f'Lecture de {df.count()} lignes depuis $goldTable')

# Écrire vers PostgreSQL
df.write \
    .format('jdbc') \
    .option('url', '$JDBC_URL') \
    .option('dbtable', 'public.$tableName') \
    .option('user', '$POSTGRES_USER') \
    .option('password', '$POSTGRES_PASSWORD') \
    .option('driver', 'org.postgresql.Driver') \
    .mode('overwrite') \
    .save()

print(f'✓ Table $tableName copiée vers TimescaleDB')
spark.stop()
"@
    
    # Sauvegarder le script temporaire
    $tempScript = "copy_${tableName}_temp.py"
    $pythonScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    # Copier dans le conteneur et exécuter
    docker cp $tempScript spark-iceberg:/tmp/
    docker exec spark-iceberg spark-submit /tmp/$tempScript
    
    # Nettoyer
    Remove-Item $tempScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Succès: $tableName" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Échec: $tableName" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Vérification des tables dans TimescaleDB" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Vérifier les tables dans PostgreSQL
docker exec timescaledb psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\dt public.gold_*"

Write-Host "`n✅ Copie terminée!`n" -ForegroundColor Green
