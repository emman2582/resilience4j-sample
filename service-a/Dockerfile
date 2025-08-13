# Build and run Service A
# Option 1 (recommended): build JAR locally with Gradle, then docker build .
# Option 2: use multi-stage build to compile inside the container.

# -------- Option 2: build stage --------
FROM gradle:8.7.0-jdk21-alpine AS build
WORKDIR /workspace
COPY ../.. /workspace
RUN gradle :service-a:bootJar --no-daemon

# -------- Runtime stage --------
FROM eclipse-temurin:21-jre
WORKDIR /app
# Copy the built jar (works for both options)
COPY build/libs/service-a-*.jar /app/app.jar
# If using multi-stage build above, uncomment next line instead:
# COPY --from=build /workspace/service-a/build/libs/service-a-*.jar /app/app.jar

ENV JAVA_OPTS="-XX:+UseG1GC"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
