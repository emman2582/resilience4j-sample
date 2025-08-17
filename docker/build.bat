@echo off
REM Docker Build Script for Windows
REM Builds Spring Boot JARs and Docker images

echo 🏗️ Building Resilience4j Docker images...

REM Navigate to project root
cd ..

REM Build Spring Boot JARs
echo 📦 Building Spring Boot applications...
gradlew.bat clean build

REM Build Docker images
echo 🐳 Building Docker images...
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

echo ✅ Build completed successfully!
echo.
echo 📋 Built images:
echo    • r4j-sample-service-a:0.1.0
echo    • r4j-sample-service-b:0.1.0
echo.
echo 🚀 Next steps:
echo    cd docker
echo    docker compose up -d