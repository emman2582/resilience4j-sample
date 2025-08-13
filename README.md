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

## 🔧 Troubleshooting

### Build Issues

**Gradle build fails:**
```bash
# Clear Gradle cache
gradle clean
rm -rf ~/.gradle/caches/

# Check Java version
java -version  # Should be 21+

# Rebuild
gradle clean build --refresh-dependencies
```

**OpenTelemetry dependency conflicts:**
```bash
# Check for version conflicts
gradle dependencies --configuration compileClasspath

# If ClassNotFoundException occurs, verify BOM versions in build.gradle.kts
```

### Runtime Issues

**Service won't start:**
```bash
# Check port availability
netstat -an | findstr :8080
netstat -an | findstr :8081

# Check application logs
gradle :service-a:bootRun --debug
```

**Connection refused between services:**
```bash
# Verify Service B is running first
curl http://localhost:8081/actuator/health

# Check Service A configuration
# Ensure B_URL environment variable is set correctly
```

**Circuit breaker not triggering:**
```bash
# Increase failure rate
curl "http://localhost:8080/api/a/flaky?failRate=80"

# Check circuit breaker metrics
curl http://localhost:8080/actuator/metrics/resilience4j.circuitbreaker.calls
```

### Docker Issues

**Image build fails:**
```bash
# Ensure JAR files exist
ls -la service-a/build/libs/
ls -la service-b/build/libs/

# Rebuild JARs
gradle clean build
```

**Container startup issues:**
```bash
# Check container logs
docker logs service-a
docker logs service-b

# Verify network connectivity
docker network ls
docker network inspect r4j-sample_r4j-net
```

**Port conflicts:**
```bash
# Check what's using ports
netstat -tulpn | grep :8080
netstat -tulpn | grep :9090

# Stop conflicting services
docker ps
docker stop <container-id>
```

### Monitoring Issues

**Prometheus not scraping metrics:**
```bash
# Check Prometheus targets
# Go to http://localhost:9090/targets

# Verify service endpoints
curl http://localhost:8080/actuator/prometheus
curl http://localhost:8081/actuator/prometheus
```

**Grafana dashboard shows no data:**
```bash
# Verify Prometheus data source
# URL should be: http://prometheus:9090 (Docker) or http://localhost:9090 (local)

# Check if metrics exist in Prometheus
# Go to http://localhost:9090 and search for "resilience4j"
```

**OpenTelemetry Collector issues:**
```bash
# Check collector logs
docker logs otel-collector

# Verify collector endpoints
curl http://localhost:4318/v1/traces  # Should return method not allowed
curl http://localhost:9464/metrics    # Should return metrics
```

### Performance Issues

**High memory usage:**
```bash
# Check JVM memory settings
# Add to application.yml:
# server:
#   tomcat:
#     max-threads: 50

# Monitor JVM metrics
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

**Slow response times:**
```bash
# Check thread pool metrics
curl http://localhost:8080/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls

# Monitor HTTP request metrics
curl http://localhost:8080/actuator/metrics/http.server.requests
```

### Common Error Messages

**"Connection refused"**
- Service B not started or wrong port
- Firewall blocking connections
- Wrong B_URL configuration

**"ClassNotFoundException: io.opentelemetry.api.incubator"**
- OpenTelemetry version mismatch
- Use compatible BOM version (2.4.0 or lower)

**"Port already in use"**
- Another service using the same port
- Kill existing processes: `taskkill /F /PID <pid>`

**"No such host"**
- DNS resolution issues
- Use IP addresses instead of hostnames
- Check /etc/hosts or Windows hosts file

## 🧹 Cleanup

```bash
# Docker Compose
docker compose down

# Kubernetes
cd k8s && ./cleanup.sh

# Clean Gradle cache
gradle clean

# Remove Docker images
docker rmi r4j-sample-service-a:0.1.0 r4j-sample-service-b:0.1.0
```