# JARs Directory

Ce répertoire contient les JARs nécessaires pour l'intégration AWS S3 avec Spark.

## ⚠️ Important

Les fichiers JAR ne sont **pas versionnés dans Git** car ils dépassent la limite de 100 MB de GitHub.

## 📦 JARs Requis

Vous devez télécharger manuellement les JARs suivants :

### 1. hadoop-aws-3.3.4.jar (~120 MB)

```bash
curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
```

**Ou télécharger depuis** : https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

### 2. aws-java-sdk-bundle-1.12.262.jar (~268 MB)

```bash
curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

**Ou télécharger depuis** : https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

## 🚀 Installation Rapide

### Windows (PowerShell)

```powershell
# Créer le répertoire jars s'il n'existe pas
New-Item -ItemType Directory -Force -Path jars
cd jars

# Télécharger hadoop-aws
Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar" -OutFile "hadoop-aws-3.3.4.jar"

# Télécharger aws-java-sdk-bundle
Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar" -OutFile "aws-java-sdk-bundle-1.12.262.jar"

cd ..
```

### Linux/Mac (Bash)

```bash
# Créer le répertoire jars s'il n'existe pas
mkdir -p jars
cd jars

# Télécharger hadoop-aws
curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

# Télécharger aws-java-sdk-bundle
curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

cd ..
```

## ✅ Vérification

Après le téléchargement, vérifiez que les fichiers sont présents :

```bash
ls -lh jars/
```

Vous devriez voir :
```
hadoop-aws-3.3.4.jar              (~120 MB)
aws-java-sdk-bundle-1.12.262.jar  (~268 MB)
```

## 🔧 Utilisation

Ces JARs sont automatiquement montés dans le conteneur Spark via `docker-compose.yml` :

```yaml
volumes:
  - ./jars:/opt/spark/extra-jars
```

Et utilisés dans les scripts PySpark :

```bash
spark-submit \
  --jars /opt/spark/extra-jars/hadoop-aws-3.3.4.jar,/opt/spark/extra-jars/aws-java-sdk-bundle-1.12.262.jar \
  mon_script.py
```

## 📚 Documentation

Pour plus d'informations, consultez :
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - Section "Download AWS SDK JARs"
- [README.md](../README.md) - Section "Installation"

## ℹ️ Pourquoi ces JARs ?

- **hadoop-aws** : Implémentation du filesystem S3A pour Hadoop, permettant à Spark de lire/écrire sur S3/MinIO
- **aws-java-sdk-bundle** : SDK AWS complet pour Java, nécessaire pour l'authentification et les opérations S3

## 🔗 Références

- [Apache Hadoop AWS Support](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html)
- [AWS SDK for Java](https://aws.amazon.com/sdk-for-java/)
- [Maven Central Repository](https://repo1.maven.org/maven2/)
