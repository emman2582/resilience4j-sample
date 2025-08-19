# Docker Deployment

Containerized deployment of Resilience4j microservices with monitoring stack.

## 🆕 Recent Improvements

- **📁 Organized Structure**: Scripts are now organized into `testing/` and `maintenance/` subdirectories
- **🧪 Comprehensive Testing**: New `test-docker-compose.sh` script tests all patterns in one go
- **🧹 Better Cleanup**: Consolidated cleanup scripts and added `.gitignore` for log files
- **📊 Streamlined Scripts**: Removed redundant test scripts, kept the best versions
- **📝 Clear Documentation**: Updated README with better organization and examples

## 📁 Directory Structure

```
docker/
├── configs/                    # Configuration files
│   ├── prometheus.yml         # Prometheus scraping config
│   ├── otel-collector-config.yml # OpenTelemetry collector config
│   ├── nginx.conf            # Load balancer config
│   └── custom-values.yaml    # Custom Helm values
├── dashboards/               # Grafana dashboards
│   ├── grafana-dashboard.json
│   ├── grafana-dashboard-enhanced.json
│   ├── grafana-dashboard-golden-metrics.json
│   ├── grafana-dashboard-opentelemetry.json
│   └── grafana-dashboard-updated.json
├── scripts/                  # Organized scripts
│   ├── testing/             # Test scripts
│   │   ├── test-docker-compose.sh    # Docker Compose tests
│   │   ├── test-bulkhead-comprehensive.sh # Bulkhead tests
│   │   ├── test-circuit-breaker.sh    # Circuit breaker tests
│   │   ├── test-resilience.sh         # Comprehensive K8s tests
│   │   └── check-bulkhead-config.sh   # Configuration checks
│   └── maintenance/         # Maintenance scripts
│       ├── cleanup.sh       # Cleanup containers
│       ├── diagnose-metrics.sh # Metrics diagnostics
│       ├── fix-metrics.sh   # Fix common issues
│       └── restart-service-a.sh # Service restart
├── swarm/                   # Docker Swarm deployment
│   ├── docker-compose-swarm.yml # Swarm stack definition
│   ├── setup-swarm.sh       # Initialize swarm
│   ├── start-autoscaler.sh  # Start autoscaling
│   ├── test-scaling.sh      # Test scaling behavior
│   └── autoscaler.py        # Python autoscaler
├── build.sh / build.bat     # Build scripts
├── docker-compose.yml       # Main compose file
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## 🚀 Quick Start

### Standard Deployment
```bash
# Build images (Linux/Mac)
./build.sh

# Build images (Windows)
.\build.bat

# Start stack
docker compose up -d
```

### Docker Swarm Deployment

**Prerequisites:**
- Python 3.x (for autoscaler)
- Docker with Swarm mode

```bash
# From project root, build images first
./gradlew clean build

# Initialize swarm
cd docker/swarm
./setup-swarm.sh

# Start autoscaler (optional - requires Python)
./start-autoscaler.sh     # Linux/Mac
# OR
start-autoscaler.bat      # Windows
```

**Alternative - Build from swarm directory:**
```bash
cd docker/swarm
./build-images.sh  # Builds from project root
./setup-swarm.sh   # Skip build step
```

## 📊 Access Points

- **Service A**: http://localhost:8080
- **Service B**: http://localhost:8081
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Load Balancer**: http://localhost (Swarm only)

## 📈 Monitoring Setup

### Automatic Dashboard Loading
```bash
# Load Grafana dashboards automatically
cd ../grafana
./scripts/load-dashboards.sh
```

**Note:** Dashboard loading scripts work without external dependencies (no `jq` required).

### Manual Prometheus Datasource Setup
```bash
# Setup Prometheus datasource only
cd ../grafana
./scripts/setup-prometheus-datasource.sh http://localhost:3000 admin admin local
```

### Prometheus Configuration
Prometheus is configured to scrape metrics from:
- Service A: `http://service-a:8080/actuator/prometheus`
- Service B: `http://service-b:8081/actuator/prometheus`

Configuration file: [`configs/prometheus.yml`](configs/prometheus.yml)

### Available Dashboards
- **Enhanced Dashboard**: Comprehensive Resilience4j metrics
- **Golden Metrics Dashboard**: Key performance indicators (SLIs)
- **OpenTelemetry Dashboard**: OTel collector and observability metrics
- **Updated Dashboard**: Latest monitoring improvements
- **Basic Dashboard**: Simple overview metrics

Dashboard files: [`dashboards/`](dashboards/)

## 🧪 Testing

### Quick Testing (Docker Compose)
```bash
# Comprehensive test suite for Docker Compose
./scripts/testing/test-docker-compose.sh
```

### Individual Pattern Testing
```bash
# Test circuit breaker pattern
./scripts/testing/test-circuit-breaker.sh

# Test bulkhead isolation
./scripts/testing/test-bulkhead-comprehensive.sh

# Comprehensive resilience testing (K8s)
./scripts/testing/test-resilience.sh

# Check bulkhead configuration
./scripts/testing/check-bulkhead-config.sh
```

### Docker Swarm Testing
```bash
# Test scaling behavior
./swarm/test-scaling.sh

# Test autoscaler implementation
./swarm/test-autoscaler.sh
```

### Health Checks
```bash
# Test monitoring stack
curl http://localhost:9090/api/v1/query?query=up  # Prometheus health
curl http://localhost:3000/api/health             # Grafana health
curl http://localhost:8080/actuator/health        # Service A health
curl http://localhost:8081/actuator/health        # Service B health
```

### Troubleshooting
```bash
# Diagnose metrics issues
./scripts/maintenance/diagnose-metrics.sh

# Fix common metrics problems
./scripts/maintenance/fix-metrics.sh

# Restart services
./scripts/maintenance/restart-service-a.sh
```

## 🔧 Troubleshooting

### No Metrics in Grafana Dashboards
```bash
# Diagnose the issue
./scripts/diagnose-metrics.sh

# Apply common fixes
./scripts/fix-metrics.sh

# Manual checks
curl http://localhost:8080/actuator/prometheus  # Service metrics
curl http://localhost:9090/api/v1/targets       # Prometheus targets
```

**Common Solutions:**
1. **Generate traffic**: Call service endpoints to create metrics
2. **Wait for scraping**: Prometheus scrapes every 5 seconds
3. **Check time range**: Set Grafana time range to "Last 5 minutes"
4. **Restart services**: `docker compose restart`

## 🧹 Cleanup

### Standard Cleanup
```bash
# Docker Compose cleanup
./scripts/maintenance/cleanup.sh      # Linux/Mac
./scripts/maintenance/cleanup.bat     # Windows

# Force cleanup (if containers are stuck)
./scripts/maintenance/force-cleanup.sh
```

### Docker Swarm Cleanup
```bash
# Remove swarm stack
docker stack rm resilience4j
docker swarm leave --force
```

### Complete Environment Reset
```bash
# Stop all containers and remove volumes
docker compose down -v
docker system prune -f

# Remove built images (optional)
docker rmi r4j-sample-service-a:0.1.0 r4j-sample-service-b:0.1.0
```