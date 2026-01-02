
# ---- Build stage ----
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
# Cache dependencies first
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline
# Copy sources and build
COPY src ./src
RUN mvn -q -e -DskipTests package

# ---- Runtime stage (small base image) ----
FROM eclipse-temurin:17-jre-alpine
ENV APP_HOME=/opt/app \
    JAVA_OPTS="" \
    TZ=UTC
WORKDIR ${APP_HOME}

# Add non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Copy the fat jar
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Health-friendly defaults
# (Tune memory for containers; use serial GC for small containers)
ENV _JAVA_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75 -XX:+UseSerialGC"

# Run as non-root
USER spring

# Enable graceful shutdown (SIGTERM) and quick startup
ENTRYPOINT ["sh","-c","java $JAVA_OPTS $_JAVA_OPTIONS -jar app.jar"]
``
