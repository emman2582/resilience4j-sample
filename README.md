# Resilience4j + Spring Boot Sample — Gradle Kotlin DSL

Demonstrates **circuit breaker, retry, timeout, bulkhead, and rate limiter** patterns using **Resilience4j** with **Spring Boot 3**. Includes **Prometheus** metrics and **OpenTelemetry** tracing.

## 🏗️ Architecture

- **service-a** — Client API with Resilience4j patterns
- **service-b** — Downstream API (ok/slow/flaky responses)
- **nodejs-client** — NodeJS client consuming Service A endpoints

## 📁 Project Structure

```
resilience4j-sample/
├── service-a/              # Client service with Resilience4j
├── service-b/              # Downstream service
├── nodejs-client/         # NodeJS client (Node.js v24+)
├── docker/                # Docker Compose deployment
│   ├── configs/           # Configuration files
│   ├── dashboards/        # Grafana dashboards
│   ├── scripts/           # Testing scripts
│   ├── swarm/            # Docker Swarm deployment
│   └── docker-compose.yml # Full stack deployment
├── k8s/                   # Kubernetes manifests
├── helm/                  # Helm charts
├── grafana/               # Dashboard loading scripts
├── aws-lambda/            # AWS Lambda deployment and testing
└── cloudformation-lambda/ # CloudFormation templates for Lambda
```

## 🚀 Quick Start

### Prerequisites
```bash
# Install dependencies
choco install openjdk --version=21.0.0 -y
choco install gradle --version=8.5.0 -y
```

### Local Development
```bash
# Build
./gradlew clean build

# If build fails, try fix script:
./fix-gradle-build.sh      # Linux/Mac
# OR
fix-gradle-build.bat       # Windows

# Run services
./gradlew :service-b:bootRun  # Terminal 1
./gradlew :service-a:bootRun  # Terminal 2
```

### Test Resilience Patterns

**Using cURL:**
```bash
# Basic connectivity
curl http://localhost:8080/api/a/ok

# Circuit Breaker + Retry
curl "http://localhost:8080/api/a/flaky?failRate=60"

# TimeLimiter + Fallback
curl "http://localhost:8080/api/a/slow?delayMs=2500"

# Bulkhead isolation
curl http://localhost:8080/api/a/bulkhead/x
curl http://localhost:8080/api/a/bulkhead/y

# Rate Limiter
curl http://localhost:8080/api/a/limited
```

**Using NodeJS Client:**
```bash
cd nodejs-client
npm install
npm start                    # Test all endpoints
npm run test:performance     # Load testing
```

## 🐳 Docker Deployment

### Build Images
```bash
# From project root
./gradlew clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

# Or from docker folder
cd docker
./build.sh  # Linux/Mac
.\build.bat # Windows
```

### Docker Compose (Full Stack)
```bash
cd docker
docker compose up -d
```

### Docker Swarm (With Autoscaling)
```bash
cd docker/swarm
./setup-swarm.sh
./start-autoscaler.sh  # Optional: automated scaling
```

**Access Points:**
- Service A: http://localhost:8080
- Service A (Load Balanced): http://localhost
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

## ☸️ Kubernetes Deployment

See [`k8s/README.md`](k8s/README.md) for complete Kubernetes deployment instructions.

```bash
cd k8s
./deploy.sh
./port-forward.sh
```

## ⎈ Helm Deployment

See [`helm/README.md`](helm/README.md) for complete Helm deployment instructions.

```bash
cd helm
helm install resilience4j-stack ./resilience4j-stack
```

## λ AWS Lambda Deployment

See [`aws-lambda/README.md`](aws-lambda/README.md) for serverless deployment instructions.

```bash
# Automated deployment, testing, and cleanup
cd aws-lambda/performance-tests
./test-and-destroy.sh

# Manual deployment
cd aws-lambda
./scripts/deploy-containers.sh
```

## 📊 Monitoring

### Metrics Endpoints
- Service A: http://localhost:8080/actuator/prometheus
- Service B: http://localhost:8081/actuator/prometheus
- Health: http://localhost:8080/actuator/health

### Grafana Dashboard

**Automatic Loading:**
```bash
# Load dashboards automatically
cd grafana
./load-dashboards.sh
```

**Manual Setup:**
1. Access Grafana at http://localhost:3000 (admin/admin)
2. Add Prometheus data source: `http://prometheus:9090`
3. Import dashboard ID `12139` or use `docker/dashboards/grafana-dashboard-enhanced.json`

### Key Metrics
- `resilience4j_circuitbreaker_state`
- `resilience4j_bulkhead_available_concurrent_calls`
- `resilience4j_retry_calls_total`
- `resilience4j_ratelimiter_available_permissions`
- `http_server_requests_seconds_count`

## 🛠️ Configuration

**Resilience4j patterns** configured in `service-a/src/main/resources/application.yml`:
- Circuit Breaker: 50% failure threshold, 10s wait
- Retry: 3 attempts with exponential backoff
- Bulkhead: Semaphore-based (3 permits for X, 2 for Y)
- Rate Limiter: 5 requests per second
- TimeLimiter: 2s timeout

## 🧹 Cleanup

### Complete Project Cleanup
```bash
# Clean everything (recommended)
./cleanup-all.sh
```

### Selective Cleanup

**Docker Compose:**
```bash
cd docker && ./scripts/cleanup.sh
```

**Kubernetes (Local):**
```bash
cd k8s && ./cleanup.sh
```

**Kubernetes (AWS):**
```bash
cd k8s && ./aws-cleanup.sh resilience4j-cluster us-east-1
```

**Helm (All environments):**
```bash
cd helm && ./cleanup.sh
```

**NodeJS Client:**
```bash
cd nodejs-client
rmdir /s /q node_modules
del package-lock.json
```

**Gradle:**
```bash
gradle clean
```