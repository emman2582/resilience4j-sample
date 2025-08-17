@echo off
REM Resilience4j Stack Helm Deployment Script for Windows
REM This script builds images, loads them into Minikube, and deploys the Helm chart

setlocal enabledelayedexpansion

echo 🚀 Starting Resilience4j Stack deployment...

REM Configuration
set CHART_NAME=resilience4j-stack
set NAMESPACE=r4j-monitoring
set RELEASE_NAME=resilience4j-stack

REM Check prerequisites
echo 🔍 Checking prerequisites...

where helm >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Helm is not installed. Please install Helm 3.8+
    exit /b 1
)

where kubectl >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ kubectl is not installed. Please install kubectl
    exit /b 1
)

where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed. Please install Docker
    exit /b 1
)

where gradle >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Gradle is not installed. Please install Gradle
    exit /b 1
)

echo ✅ All prerequisites are installed

REM Build application
echo 🔨 Building application...
cd ..
gradle clean build
if %errorlevel% neq 0 (
    echo ❌ Application build failed
    exit /b 1
)
echo ✅ Application built successfully
cd helm

REM Build Docker images
echo 🐳 Building Docker images...
cd ..

docker build -t r4j-sample-service-a:0.1.0 service-a/
if %errorlevel% neq 0 (
    echo ❌ Failed to build Service A image
    exit /b 1
)
echo ✅ Service A image built

docker build -t r4j-sample-service-b:0.1.0 service-b/
if %errorlevel% neq 0 (
    echo ❌ Failed to build Service B image
    exit /b 1
)
echo ✅ Service B image built

cd helm

REM Load images into Minikube (if using Minikube)
kubectl config current-context | findstr minikube >nul
if %errorlevel% equ 0 (
    echo 📦 Loading images into Minikube...
    minikube image load r4j-sample-service-a:0.1.0
    minikube image load r4j-sample-service-b:0.1.0
    echo ✅ Images loaded into Minikube
) else (
    echo ⚠️ Not using Minikube, skipping image loading
)

REM Create namespace
echo 📁 Creating namespace...
kubectl create namespace %NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -
echo ✅ Namespace '%NAMESPACE%' ready

REM Deploy Helm chart
echo ⚡ Deploying Helm chart...

REM Lint the chart first
helm lint ./resilience4j-stack
if %errorlevel% neq 0 (
    echo ❌ Helm chart linting failed
    exit /b 1
)

REM Install or upgrade the chart
helm upgrade --install %RELEASE_NAME% ./resilience4j-stack --namespace %NAMESPACE% --wait --timeout 300s
if %errorlevel% neq 0 (
    echo ❌ Helm chart deployment failed
    exit /b 1
)
echo ✅ Helm chart deployed successfully

REM Wait for pods to be ready
echo ⏳ Waiting for pods to be ready...
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=%RELEASE_NAME% -n %NAMESPACE% --timeout=300s
if %errorlevel% equ 0 (
    echo ✅ All pods are ready
) else (
    echo ⚠️ Some pods may not be ready yet
)

REM Display deployment status
echo.
echo 📊 Deployment Status:
echo ====================
kubectl get pods -n %NAMESPACE%
echo.
kubectl get svc -n %NAMESPACE%
echo.
echo 🔗 Access URLs (after port-forwarding):
echo Service A: http://localhost:8080
echo Prometheus: http://localhost:9090
echo Grafana: http://localhost:3000 (admin/admin)
echo.
echo 📝 Port-forward commands:
echo kubectl port-forward svc/service-a 8080:8080 -n %NAMESPACE%
echo kubectl port-forward svc/prometheus 9090:9090 -n %NAMESPACE%
echo kubectl port-forward svc/grafana 3000:3000 -n %NAMESPACE%
echo.
echo ✅ Deployment completed successfully! 🎉

pause