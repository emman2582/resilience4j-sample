# Grafana Dashboard Loader

Automatically load enhanced and golden metrics dashboards into Grafana for both local and AWS cloud environments.

## 📊 Available Dashboards

- **Enhanced Dashboard** (`dashboards/grafana-dashboard-enhanced.json`) - Comprehensive Resilience4j metrics
- **Golden Metrics Dashboard** (`dashboards/grafana-dashboard-golden-metrics.json`) - Key performance indicators

## 🚀 Usage

### Local Development

**Docker Compose:**
```bash
# Start Grafana with Docker Compose
cd docker
docker compose up -d grafana

# Load dashboards
cd ../grafana
./scripts/load-dashboards.sh
```

**Kubernetes (Local):**
```bash
# Deploy to local namespace
kubectl apply -f k8s/ -n resilience4j-local

# Load dashboards
cd grafana
./scripts/load-dashboards-k8s.sh resilience4j-local local
```

### AWS Cloud

**EKS Single Node:**
```bash
# Deploy to AWS
./k8s/aws-deploy.sh resilience4j-cluster 1 us-east-1

# Load dashboards
cd grafana
./scripts/load-dashboards-k8s.sh resilience4j-aws-single single
```

**EKS Multi Node:**
```bash
# Deploy to AWS
./k8s/aws-deploy.sh resilience4j-cluster 2 us-east-1

# Load dashboards
cd grafana
./scripts/load-dashboards-k8s.sh resilience4j-aws-multi multi
```

### Manual Loading

**Direct Grafana URL:**
```bash
# Custom Grafana instance
./scripts/load-dashboards.sh http://your-grafana-url:3000 admin password aws
```

**Windows:**
```cmd
# Load dashboards on Windows
scripts\load-dashboards.bat http://localhost:3000 admin admin local
```

### Prometheus Datasource Only

**Setup datasource separately:**
```bash
# Linux/Mac
./scripts/setup-prometheus-datasource.sh http://localhost:3000 admin admin local

# Windows
scripts\setup-prometheus-datasource.bat http://localhost:3000 admin admin local
```

## ⚙️ Configuration

### Script Parameters

```bash
./scripts/load-dashboards.sh [GRAFANA_URL] [USER] [PASSWORD] [ENVIRONMENT]
```

- **GRAFANA_URL**: Grafana instance URL (default: http://localhost:3000)
- **USER**: Grafana username (default: admin)
- **PASSWORD**: Grafana password (default: admin)
- **ENVIRONMENT**: Deployment environment (local/aws)

### Environment-Specific Settings

**Local Environment:**
- Prometheus URL: `http://prometheus:9090`
- Namespace: `resilience4j-local`

**AWS Environment:**
- Prometheus URL: `http://prometheus.resilience4j-aws-single:9090`
- Namespace: `resilience4j-aws-single` or `resilience4j-aws-multi`

## 🔧 Features

- ✅ **Automatic Grafana readiness check**
- ✅ **Automated Prometheus datasource setup**
- ✅ **Dashboard overwrite protection**
- ✅ **Environment-aware configuration**
- ✅ **Error handling and reporting**
- ✅ **Windows and Linux support**
- ✅ **Datasource connection testing**

## 📈 Dashboard Content

### Enhanced Dashboard
- Circuit Breaker states and metrics
- Bulkhead capacity and usage
- Retry attempt statistics
- Rate limiter permissions
- HTTP request metrics
- JVM memory and CPU usage

### Golden Metrics Dashboard
- Request rate (RPS)
- Error rate (%)
- Response time (latency)
- Saturation (resource usage)

## 🛠️ Troubleshooting

**Grafana not accessible:**
```bash
# Check if Grafana is running
kubectl get pods -n resilience4j-local | grep grafana

# Check port forwarding
netstat -an | findstr :3000
```

**Dashboard loading fails:**
```bash
# Check Grafana logs
kubectl logs -l app=grafana -n resilience4j-local

# Verify JSON syntax
jq . grafana-dashboard-enhanced.json
```

**Data source connection issues:**
```bash
# Test Prometheus connectivity
kubectl exec -it grafana-pod -n resilience4j-local -- curl http://prometheus:9090/api/v1/query?query=up
```

## 📁 Files

```
grafana/
├── scripts/                     # Dashboard loading scripts
│   ├── load-dashboards.sh       # Main loader script (Linux/Mac)
│   ├── load-dashboards.bat      # Windows loader script
│   ├── load-dashboards-k8s.sh   # Kubernetes-specific loader
│   ├── setup-prometheus-datasource.sh   # Prometheus setup (Linux/Mac)
│   ├── setup-prometheus-datasource.bat  # Prometheus setup (Windows)
│   └── cleanup.sh               # Cleanup script
├── dashboards/                  # Dashboard JSON files
│   ├── grafana-dashboard-enhanced.json      # Enhanced dashboard
│   └── grafana-dashboard-golden-metrics.json # Golden metrics dashboard
└── README.md                    # This file

../docker/dashboards/            # Additional dashboards
├── grafana-dashboard-updated.json       # Updated dashboard
└── grafana-dashboard.json               # Basic dashboard
```