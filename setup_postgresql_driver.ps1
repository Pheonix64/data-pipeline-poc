# Script pour télécharger et installer le driver PostgreSQL JDBC dans Spark

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION DU DRIVER POSTGRESQL JDBC POUR SPARK" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$driverUrl = "https://jdbc.postgresql.org/download/postgresql-42.6.0.jar"
$driverFile = "postgresql-42.6.0.jar"
$jarDir = ".\jars"

# Créer le dossier jars s'il n'existe pas
if (-not (Test-Path $jarDir)) {
    New-Item -ItemType Directory -Path $jarDir | Out-Null
}

# Télécharger le driver si nécessaire
Write-Host ""
Write-Host "[1/3] Téléchargement du driver PostgreSQL JDBC..." -ForegroundColor Yellow
$driverPath = Join-Path $jarDir $driverFile

if (Test-Path $driverPath) {
    Write-Host "Driver déjà présent: $driverPath" -ForegroundColor Green
}
else {
    try {
        Write-Host "Téléchargement depuis $driverUrl..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $driverUrl -OutFile $driverPath -UseBasicParsing
        Write-Host "Driver téléchargé: $driverPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors du téléchargement: $_" -ForegroundColor Red
        exit 1
    }
}

# Vérifier que le conteneur Spark est en cours d'exécution
Write-Host ""
Write-Host "[2/3] Vérification du conteneur Spark..." -ForegroundColor Yellow
$sparkRunning = docker ps --filter "name=spark-iceberg" --format "{{.Names}}"
if (-not $sparkRunning) {
    Write-Host "Le conteneur spark-iceberg n'est pas en cours d'exécution." -ForegroundColor Red
    Write-Host "Démarrez-le avec: docker-compose up -d spark-iceberg" -ForegroundColor Yellow
    exit 1
}
Write-Host "Conteneur spark-iceberg actif" -ForegroundColor Green

# Copier le driver dans le conteneur Spark
Write-Host ""
Write-Host "[3/3] Copie du driver dans le conteneur Spark..." -ForegroundColor Yellow
try {
    docker cp $driverPath spark-iceberg:/opt/spark/jars/
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Driver copié dans /opt/spark/jars/" -ForegroundColor Green
        
        # Vérifier la présence du fichier
        Write-Host ""
        Write-Host "Vérification..." -ForegroundColor Yellow
        docker exec spark-iceberg ls -lh /opt/spark/jars/postgresql-42.6.0.jar
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "SUCCÈS! Le driver PostgreSQL JDBC est installé." -ForegroundColor Green
            Write-Host ""
            Write-Host "Vous pouvez maintenant exécuter: .\run_copy_uemoa.ps1" -ForegroundColor Cyan
        }
        else {
            Write-Host "Le fichier n'a pas été trouvé dans le conteneur." -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Erreur lors de la copie du driver." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    exit 1
}

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
