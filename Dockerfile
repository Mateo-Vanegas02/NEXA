# syntax=docker/dockerfile:1

# ───────────── ETAPA 1: compilación ─────────────
# Maven + JDK 21. Las dependencias se descargan en una capa aparte (y con caché de BuildKit)
# para que un cambio en src/ no vuelva a bajarlas.
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -B -q dependency:go-offline

COPY src ./src
# Los tests se ejecutan en el CI (ci.yml); aquí solo se empaqueta.
RUN --mount=type=cache,target=/root/.m2 mvn -B -q clean package -DskipTests

# ───────────── ETAPA 2: ejecución ─────────────
# Solo JRE, usuario sin privilegios y sin secretos: las variables llegan en tiempo de ejecución
# (docker compose + .env, o las variables de la plataforma).
FROM eclipse-temurin:21-jre-jammy

LABEL org.opencontainers.image.title="NEXA backend" \
      org.opencontainers.image.source="https://github.com/Mateo-Vanegas02/NEXA_Origin"

RUN groupadd --system nexa \
 && useradd --system --gid nexa --home-dir /app --shell /usr/sbin/nologin nexa
WORKDIR /app

COPY --from=build --chown=nexa:nexa /app/target/*.jar app_nexa.jar
# Modelo Weka J48: la app lo lee (y puede reescribirlo al reentrenar) desde el directorio de trabajo.
COPY --chown=nexa:nexa modelo_satisfaccion_j48_v2.0.model ./

USER nexa
EXPOSE 8080

# Memoria acotada para el servidor de 2 GB (ver CLAUDE.md). Se puede sobrescribir con -e JAVA_OPTS.
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC" \
    SPRING_PROFILES_ACTIVE=prod

# Sin Actuator en el proyecto: se comprueba que el puerto acepta conexiones.
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080' || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app_nexa.jar"]
