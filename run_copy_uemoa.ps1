# Script PowerShell pour copier les datamarts UEMOA vers TimescaleDB

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  COPIE DES DATAMARTS UEMOA VERS TIMESCALEDB" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# Vérifier que Docker est en cours d'exécution
Write-Host ""
Write-Host "[1/4] Vérification de Docker..." -ForegroundColor Yellow
try {
    $null = docker info 2>&1
    Write-Host "Docker est actif" -ForegroundColor Green
}
catch {
    Write-Host "Docker n'est pas en cours d'execution. Veuillez le demarrer." -ForegroundColor Red
    exit 1
}

# Vérifier que les conteneurs sont en cours d'exécution
Write-Host ""
Write-Host "[2/4] Vérification des conteneurs..." -ForegroundColor Yellow
$sparkRunning = docker ps --filter "name=spark-iceberg" --format "{{.Names}}"
$timescaleRunning = docker ps --filter "name=timescaledb" --format "{{.Names}}"

if (-not $sparkRunning) {
    Write-Host "Le conteneur spark-iceberg n'est pas en cours d'exécution." -ForegroundColor Red
    exit 1
}
Write-Host "spark-iceberg est actif" -ForegroundColor Green

if (-not $timescaleRunning) {
    Write-Host "Le conteneur timescaledb n'est pas en cours d'exécution." -ForegroundColor Red
    exit 1
}
Write-Host "timescaledb est actif" -ForegroundColor Green

# Copier le script Python dans le conteneur Spark
Write-Host ""
Write-Host "[3/4] Copie du script dans le conteneur Spark..." -ForegroundColor Yellow
docker cp copy_uemoa_to_timescale.py spark-iceberg:/tmp/
if (-not $?) {
    Write-Host "Erreur lors de la copie du script." -ForegroundColor Red
    exit 1
}
Write-Host "Script copié dans /tmp/" -ForegroundColor Green

# Exécuter le script avec Spark Submit
Write-Host ""
Write-Host "[4/4] Exécution du script de copie..." -ForegroundColor Yellow
Write-Host "Cela peut prendre quelques minutes..." -ForegroundColor Yellow
Write-Host ""

docker exec spark-iceberg spark-submit --driver-class-path /opt/spark/jars/postgresql-42.6.0.jar --jars /opt/spark/jars/postgresql-42.6.0.jar /tmp/copy_uemoa_to_timescale.py

$exitCode = $LASTEXITCODE

# Résultat final
Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "SUCCÈS! Les datamarts UEMOA ont été copiés vers TimescaleDB" -ForegroundColor Green
    
    # Afficher les tables créées
    Write-Host ""
    Write-Host "Vérification des tables dans TimescaleDB..." -ForegroundColor Yellow
    docker exec timescaledb psql -U postgres -d monetary_policy_dm -c "SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'gold_%' ORDER BY table_name;"
    
    Write-Host ""
    Write-Host "Pour interroger les données, utilisez:" -ForegroundColor Cyan
    Write-Host "   docker exec -it timescaledb psql -U postgres -d monetary_policy_dm" -ForegroundColor White
    Write-Host ""
    Write-Host "   Exemples de requêtes:" -ForegroundColor Cyan
    Write-Host "   SELECT * FROM gold_mart_uemoa_monetary_dashboard LIMIT 5;" -ForegroundColor White
    Write-Host "   SELECT pays, COUNT(*) FROM gold_mart_uemoa_public_finance GROUP BY pays;" -ForegroundColor White
    
}
else {
    Write-Host "ERREUR! La copie a échoué. Consultez les logs ci-dessus." -ForegroundColor Red
}
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

exit $exitCode
