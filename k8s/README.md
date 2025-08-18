# Resilience4j Kubernetes Deployment

Simplified Kubernetes deployment for Resilience4j sample application with monitoring.

## 📁 Project Structure

```
k8s/
├── local/                 # Local minikube deployment
│   └── all-in-one.yaml    # Complete local stack
├── single/                # AWS single-node deployment  
│   └── all-in-one.yaml    # Complete single-node stack
├── multi/                 # AWS multi-node deployment
│   └── all-in-one.yaml    # Complete multi-node stack with HPA
├── aws/                   # AWS cluster configurations
│   ├── single-cluster.yaml # Single-node EKS config
│   ├── multi-cluster.yaml  # Multi-node EKS config
│   └── setup.sh           # AWS cluster setup script
├── deploy.sh              # Universal deployment script
├── cleanup.sh             # Universal cleanup script
├── test.sh                # Universal testing script
└── README.md              # This file
```

---

## 🏠 Local Environment (Minikube)

### Prerequisites
- Minikube installed and running
- Docker images built locally

### Setup
```bash
# Start minikube
minikube start --memory=4096 --cpus=2

# Build images
cd ../
./gradlew clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

# Load images into minikube
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0
```

### Deploy
```bash
cd k8s
./deploy.sh local
```

### Access Services
```bash
# Method 1: Use port forwarding script (recommended)
./port-forward.sh resilience4j-local
# or on Windows:
# .\port-forward.bat resilience4j-local

# Method 2: Manual port forwarding (if script fails)
kubectl port-forward svc/service-a 8082:8080 -n resilience4j-local &
kubectl port-forward svc/grafana 3001:3000 -n resilience4j-local &
kubectl port-forward svc/prometheus 9091:9090 -n resilience4j-local &

# Access points (ports may vary based on availability):
# Service A: http://localhost:8080 (or next available port)
# Grafana: http://localhost:3000 (admin/admin) (or next available port)
# Prometheus: http://localhost:9090 (or next available port)
```

### Test
```bash
./test.sh local
```

### Cleanup
```bash
./cleanup.sh local
```

---

## ☁️ AWS Single-Node Environment

### Prerequisites
- AWS CLI configured
- eksctl installed
- kubectl installed
- Docker installed

### Setup Cluster
```bash
cd k8s/aws
./setup.sh single us-east-1
```

### Deploy Application

**Method 1: ALB-First Deployment (Recommended for AWS)**
```bash
cd k8s/aws
./deploy-with-alb.sh single us-east-1
```

**Method 2: Standard Deployment**
```bash
cd k8s
./deploy.sh single us-east-1
```

### Access Services

**ALB-First Deployment:**
```bash
# ALB endpoints (ready immediately after deployment)
# Service A: http://ALB_DNS_NAME/
# Grafana: http://ALB_DNS_NAME/grafana (admin/admin)

# Get ALB DNS name
source k8s/aws/alb-config-single.env && echo $ALB_DNS

# Test endpoints
curl http://$ALB_DNS/actuator/health
curl http://$ALB_DNS/grafana/api/health
```

**Standard Deployment:**
```bash
# Primary method: Port forwarding
kubectl port-forward svc/service-a 8080:8080 -n resilience4j-single &
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-single &
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-single &

# Access points:
# Service A: http://localhost:8080
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090
```

### Test
```bash
./test.sh single
```

### Cleanup

**ALB-First Deployment:**
```bash
# Clean up ALB resources and applications
cd k8s/aws
./cleanup-alb.sh single us-east-1

# Full cleanup (cluster + ECR)
eksctl delete cluster resilience4j-dev --region us-east-1
aws ecr delete-repository --repository-name r4j-sample-service-a --region us-east-1 --force
aws ecr delete-repository --repository-name r4j-sample-service-b --region us-east-1 --force
```

**Standard Deployment:**
```bash
# Application only
./cleanup.sh single

# Full cleanup (cluster + ECR)
eksctl delete cluster resilience4j-dev --region us-east-1
aws ecr delete-repository --repository-name r4j-sample-service-a --region us-east-1 --force
aws ecr delete-repository --repository-name r4j-sample-service-b --region us-east-1 --force
```

---

## ☁️ AWS Multi-Node Environment

### Prerequisites
- AWS CLI configured
- eksctl installed
- kubectl installed
- Docker installed

### Setup Cluster
```bash
cd k8s/aws
./setup.sh multi us-east-1
```

### Deploy Application

**Method 1: ALB-First Deployment (Recommended for AWS)**
```bash
cd k8s/aws
./deploy-with-alb.sh multi us-east-1
```

**Method 2: Standard Deployment**
```bash
cd k8s
./deploy.sh multi us-east-1
```

### Access Services

**ALB-First Deployment:**
```bash
# ALB endpoints (ready immediately after deployment)
# Service A: http://ALB_DNS_NAME/
# Grafana: http://ALB_DNS_NAME/grafana (admin/admin)

# Get ALB DNS name
source k8s/aws/alb-config-multi.env && echo $ALB_DNS

# Monitor autoscaling
kubectl get hpa -n resilience4j-multi -w

# Test endpoints
curl http://$ALB_DNS/actuator/health
curl http://$ALB_DNS/grafana/api/health
```

**Standard Deployment:**
```bash
# Primary method: Port forwarding
kubectl port-forward svc/service-a 8080:8080 -n resilience4j-multi &
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-multi &
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-multi &

# Access points:
# Service A: http://localhost:8080
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090

# Monitor autoscaling
kubectl get hpa -n resilience4j-multi -w
```

### Test
```bash
./test.sh multi

# Test autoscaling
for i in {1..100}; do curl -s http://ALB_URL/api/a/slow?delayMs=2000 & done
kubectl get hpa -n resilience4j-multi -w
```

### Cleanup

**ALB-First Deployment:**
```bash
# Clean up ALB resources and applications
cd k8s/aws
./cleanup-alb.sh multi us-east-1

# Full cleanup (cluster + ECR)
eksctl delete cluster resilience4j-prod --region us-east-1
aws ecr delete-repository --repository-name r4j-sample-service-a --region us-east-1 --force
aws ecr delete-repository --repository-name r4j-sample-service-b --region us-east-1 --force
```

**Standard Deployment:**
```bash
# Application only
./cleanup.sh multi

# Full cleanup (cluster + ECR)
eksctl delete cluster resilience4j-prod --region us-east-1
aws ecr delete-repository --repository-name r4j-sample-service-a --region us-east-1 --force
aws ecr delete-repository --repository-name r4j-sample-service-b --region us-east-1 --force
```

---

## 🧪 Testing Resilience Patterns

### Available Endpoints
```bash
# Health check
curl http://BASE_URL/actuator/health

# Circuit breaker (fails at 60% rate)
curl "http://BASE_URL/api/a/flaky?failRate=60"

# Timeout (2s limit)
curl "http://BASE_URL/api/a/slow?delayMs=3000"

# Bulkhead isolation
curl http://BASE_URL/api/a/bulkhead/x
curl http://BASE_URL/api/a/bulkhead/y

# Rate limiter (5 req/sec limit)
curl http://BASE_URL/api/a/limited
```

### Load Testing
```bash
# Light load (local)
for i in {1..20}; do curl -s http://localhost:8080/api/a/ok & done

# Medium load (single-node)
for i in {1..50}; do curl -s http://ALB_URL/api/a/ok & done

# Heavy load (multi-node)
for i in {1..100}; do curl -s http://ALB_URL/api/a/ok & done
```

---

## 🌐 Network Architecture

### AWS Single/Multi-Node Architecture
```
Internet
    |
    v
[Application Load Balancer] (Single Entry Point)
    |
    +-- /grafana/* --> ClusterIP:grafana:3000
    +-- /prometheus/* --> ClusterIP:prometheus:9090  
    +-- /* --> ClusterIP:service-a:8080
                    |
                    v
            ClusterIP:service-b:8081
```

### Network Configuration
- **ALB**: Single internet-facing entry point
- **ClusterIP Services**: Internal pod communication only
- **Network Policies**: Restrict direct pod access (optional)
- **Health Checks**: ALB monitors pod health via ClusterIP services

### Security Benefits
- No direct internet access to pods
- All traffic routed through ALB
- Internal service-to-service communication via ClusterIP
- Optional network policies for additional security

---

## 📊 Monitoring & Grafana Setup

### Automated Dashboard Loading (Recommended)

**Local Environment:**
```bash
# Load dashboards and setup Prometheus datasource automatically
cd ../grafana
./scripts/load-dashboards-k8s.sh resilience4j-local local

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-local &
# Open browser: http://localhost:3000 (admin/admin)
```

**Single-Node Environment:**
```bash
# Load dashboards and setup Prometheus datasource automatically
cd ../grafana
./scripts/load-dashboards-k8s.sh resilience4j-single single

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-single &
# Open browser: http://localhost:3000 (admin/admin)
```

**Multi-Node Environment:**
```bash
# Load dashboards and setup Prometheus datasource automatically
cd ../grafana
./scripts/load-dashboards-k8s.sh resilience4j-multi multi

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-multi &
# Open browser: http://localhost:3000 (admin/admin)
```

### Manual Setup (Alternative)

**Access Grafana:**
```bash
# Port forward to Grafana
kubectl port-forward svc/grafana 3000:3000 -n NAMESPACE &

# Login: admin/admin at http://localhost:3000
```

**Setup Prometheus Datasource:**
```bash
# Use automated script
cd ../grafana
./scripts/setup-prometheus-datasource.sh http://localhost:3000 admin admin ENVIRONMENT

# Or manually:
# 1. Go to Configuration → Data Sources
# 2. Add Prometheus datasource
# 3. URL: http://prometheus:9090
# 4. Save & Test
```

**Load Dashboards:**
```bash
# Use automated script
cd ../grafana
./scripts/load-dashboards.sh http://localhost:3000 admin admin ENVIRONMENT

# Available dashboards:
# - grafana-dashboard-enhanced.json (comprehensive metrics)
# - grafana-dashboard-golden-metrics.json (key metrics only)
```

### Pre-built Dashboards

**Enhanced Dashboard** (`grafana-dashboard-enhanced.json`):
- Circuit Breaker states and metrics
- Bulkhead concurrent calls and queue metrics
- Retry attempts and success rates
- Rate Limiter permissions and wait times
- HTTP request metrics (rate, errors, duration)
- JVM metrics (memory, GC, threads)
- System metrics (CPU, load)

**Golden Metrics Dashboard** (`grafana-dashboard-golden-metrics.json`):
- Request Rate (throughput)
- Error Rate (reliability)
- Response Time (latency)
- Saturation (resource utilization)

### Key Metrics Monitored
- `resilience4j_circuitbreaker_state` - Circuit breaker status
- `resilience4j_bulkhead_available_concurrent_calls` - Bulkhead capacity
- `resilience4j_retry_calls_total` - Retry attempts
- `resilience4j_ratelimiter_available_permissions` - Rate limiter status
- `http_server_requests_seconds_count` - HTTP request metrics
- `jvm_memory_used_bytes` - JVM memory usage
- `process_cpu_usage` - CPU utilization

---

## 🔧 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl get pods -n NAMESPACE
kubectl describe pod POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE
```

**Images not found (local):**
```bash
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0
```

**ALB not accessible (AWS):**
```bash
# Check ingress status
kubectl get ingress -n NAMESPACE
kubectl describe ingress resilience4j-ingress -n NAMESPACE

# Check ALB controller
kubectl get deployment aws-load-balancer-controller -n kube-system

# Use port forwarding as fallback
kubectl port-forward svc/service-a 8080:8080 -n NAMESPACE
```

**EKS access denied:**
```bash
aws eks update-kubeconfig --region REGION --name CLUSTER_NAME
kubectl get nodes
```

---

## 📋 Quick Reference

### Environment Comparison

| Feature | Local | Single-Node | Multi-Node |
|---------|-------|-------------|------------|
| **Namespace** | resilience4j-local | resilience4j-single | resilience4j-multi |
| **Service A Replicas** | 2 | 1 | 2+ (HPA) |
| **Service B Replicas** | 1 | 1 | 2 |
| **Internet Access** | Port forwarding | ALB (single entry) | ALB (single entry) |
| **Service Type** | ClusterIP | ClusterIP | ClusterIP |
| **Network Policy** | None | Optional | Optional |
| **Autoscaling** | None | None | HPA enabled |
| **Cost** | Free | ~$50/month | ~$100-250/month |

### Command Summary

```bash
# Deploy
./deploy.sh [local|single|multi] [region]

# Test  
./test.sh [local|single|multi]

# Cleanup
./cleanup.sh [local|single|multi|all]

# AWS Setup
cd aws && ./setup.sh [single|multi] [region]

# Grafana Setup & Access
cd ../grafana/scripts && ./load-dashboards-k8s.sh resilience4j-[local|single|multi] [local|single|multi]
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-[local|single|multi]
```