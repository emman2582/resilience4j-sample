# Resilience4j + Spring Boot Sample — Gradle Kotlin DSL

Demonstrates **circuit breaker, retry, timeout, bulkhead, and rate limiter** patterns using **Resilience4j** with **Spring Boot 3**. Includes **Prometheus** metrics and **OpenTelemetry** tracing.

## 🏗️ Architecture

- **service-a** — Client API with Resilience4j patterns
- **service-b** — Downstream API (ok/slow/flaky responses)

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
gradle clean build

# Run services
gradle :service-b:bootRun  # Terminal 1
gradle :service-a:bootRun  # Terminal 2
```

### Test Resilience Patterns
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

## 🐳 Docker Deployment

### Build Images
```bash
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/
```

### Docker Compose (Full Stack)
```bash
docker compose up -d
```

**Access Points:**
- Service A: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

## ⚙️ Kubernetes Deployment

See [`k8s/README.md`](k8s/README.md) for complete Kubernetes deployment instructions.

```bash
cd k8s
./deploy.sh
./port-forward.sh
```

## 📊 Monitoring

### Metrics Endpoints
- Service A: http://localhost:8080/actuator/prometheus
- Service B: http://localhost:8081/actuator/prometheus
- Health: http://localhost:8080/actuator/health

### Grafana Dashboard
1. Access Grafana at http://localhost:3000 (admin/admin)
2. Add Prometheus data source: `http://prometheus:9090`
3. Import dashboard ID `12139` or use `grafana-dashboard-enhanced.json`

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

## 📁 Project Structure

```
resilience4j-sample/
├── service-a/              # Client service with Resilience4j
├── service-b/              # Downstream service
├── k8s/                   # Kubernetes manifests
├── docker-compose.yml     # Full stack deployment
├── prometheus.yml         # Metrics scraping config
├── otel-collector-config.yml  # OpenTelemetry config
└── grafana-dashboard-*.json   # Grafana dashboards
```

## 🧹 Cleanup

```bash
# Docker Compose
docker compose down

# Kubernetes
cd k8s && ./cleanup.sh
```