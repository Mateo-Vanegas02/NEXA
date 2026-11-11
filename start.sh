#!/bin/bash
# Script de inicio para servidor sin Docker (VPS 2GB)

# Si el puerto 8080 esta en uso, puedes cambiarlo aqui o en application-prod.properties
PORT=8080
JAR_FILE="target/MotvirsWeb-0.0.1-SNAPSHOT.jar"

# Limites de memoria para la JVM (Importante para 2GB de RAM)
JAVA_OPTS="-Xms512m -Xmx1024m"

# Verificar que el JAR exista
if [ ! -f "$JAR_FILE" ]; then
    echo "El archivo $JAR_FILE no existe. Asegurate de ejecutar 'mvn clean package' primero."
    exit 1
fi

echo "Iniciando la aplicacion en el puerto $PORT con opciones $JAVA_OPTS..."

# Ejecutar en segundo plano con el perfil de produccion
nohup java $JAVA_OPTS -Dspring.profiles.active=prod -jar $JAR_FILE > app.log 2>&1 &

echo "Aplicacion iniciada en segundo plano. Revisa app.log para ver los registros."
