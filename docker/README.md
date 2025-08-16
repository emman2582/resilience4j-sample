# Docker Deployment

Containerized deployment of Resilience4j microservices with monitoring stack.

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
│   └── grafana-dashboard-updated.json
├── scripts/                  # Testing and utility scripts
│   ├── cleanup.sh           # Cleanup containers
│   ├── test-circuit-breaker.sh # Circuit breaker tests
│   ├── test-bulkhead.sh     # Bulkhead tests
│   └── restart-service-a.sh # Service restart
├── swarm/                   # Docker Swarm deployment
│   ├── docker-compose-swarm.yml # Swarm stack definition
│   ├── setup-swarm.sh       # Initialize swarm
│   ├── start-autoscaler.sh  # Start autoscaling
│   ├── test-scaling.sh      # Test scaling behavior
│   └── autoscaler.py        # Python autoscaler
├── docker-compose.yml       # Main compose file
└── README.md               # This file
```

## 🚀 Quick Start

### Standard Deployment
```bash
# Build images
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

# Start stack
docker compose up -d
```

### Docker Swarm Deployment
```bash
# Initialize swarm
cd swarm
./setup-swarm.sh

# Start autoscaler (optional)
./start-autoscaler.sh
```

## 📊 Access Points

- **Service A**: http://localhost:8080
- **Service B**: http://localhost:8081
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Load Balancer**: http://localhost (Swarm only)

## 🧪 Testing

```bash
# Test circuit breaker
./scripts/test-circuit-breaker.sh

# Test bulkhead
./scripts/test-bulkhead.sh

# Test scaling (Swarm)
./swarm/test-scaling.sh
```

## 🧹 Cleanup

```bash
# Standard cleanup
./scripts/cleanup.sh

# Swarm cleanup
docker stack rm resilience4j
docker swarm leave --force
```