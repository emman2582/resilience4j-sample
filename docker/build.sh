#!/bin/bash

# Docker Build Script
# Builds Spring Boot JARs and Docker images

echo "🏗️ Building Resilience4j Docker images..."

# Navigate to project root
cd ..

# Build Spring Boot JARs locally
echo "📦 Building Spring Boot applications..."
./gradlew clean build

if [ $? -ne 0 ]; then
    echo "❌ Gradle build failed!"
    exit 1
fi

# Create simple Dockerfiles for local build
echo "🐳 Building Docker images..."

# Build service-a
cat > service-a/Dockerfile.local << 'EOF'
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN mkdir -p /app/logs
COPY build/libs/service-a-*.jar /app/app.jar
ENV JAVA_OPTS="-XX:+UseG1GC -Dlogging.config=classpath:logback-spring.xml"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
EOF

# Build service-b
cat > service-b/Dockerfile.local << 'EOF'
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN mkdir -p /app/logs
COPY build/libs/service-b-*.jar /app/app.jar
ENV JAVA_OPTS="-XX:+UseG1GC -Dlogging.config=classpath:logback-spring.xml"
EXPOSE 8081
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
EOF

docker build -f service-a/Dockerfile.local -t r4j-sample-service-a:0.1.0 service-a/
docker build -f service-b/Dockerfile.local -t r4j-sample-service-b:0.1.0 service-b/
docker compose down service-a service-b

# Cleanup temp Dockerfiles
rm -f service-a/Dockerfile.local service-b/Dockerfile.local

echo "✅ Build completed successfully!"
echo ""
echo "📋 Built images:"
echo "   • r4j-sample-service-a:0.1.0"
echo "   • r4j-sample-service-b:0.1.0"
echo ""
echo "🚀 Next steps:"
echo "   cd docker"
echo "   docker compose up -d"