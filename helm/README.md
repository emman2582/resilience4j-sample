# Resilience4j Stack Helm Chart

A comprehensive Helm chart for deploying the Resilience4j microservices sample with full monitoring stack including Prometheus, Grafana, and OpenTelemetry Collector.

## 🏗️ Architecture

The chart deploys:
- **Service A** - Client service with Resilience4j patterns (Circuit Breaker, Retry, Bulkhead, Rate Limiter)
- **Service B** - Downstream service providing various response patterns
- **Prometheus** - Metrics collection and storage
- **Grafana** - Metrics visualization and dashboards
- **OpenTelemetry Collector** - Telemetry data collection and processing

## 📋 Prerequisites

### Local Development
- Kubernetes 1.19+ (Minikube/Docker Desktop)
- Helm 3.8+
- Docker images built locally

### AWS Cloud
- AWS CLI configured
- eksctl installed
- Helm 3.8+
- ECR repositories (created automatically)
- IAM permissions for EKS and ECR

## 🏗️ Deployment Architectures

### Local (Minikube)
```
Namespace: resilience4j-local
Helm Chart → Minikube → Port Forward → Services
Labels: environment=local, deployment-type=minikube
```

### AWS Single Node Cluster
```
Namespace: resilience4j-aws-single
Helm Chart → EKS (1 node, t3.medium) → ALB Ingress → Services (1 replica each)
Labels: environment=aws, deployment-type=single-node, node-count=1
Cost: ~$50/month | Use Case: Development, testing
```

### AWS Multi-Node Cluster
```
Namespace: resilience4j-aws-multi
Helm Chart → EKS (2-5 nodes, t3.medium) → ALB Ingress → Services (2+ replicas)
Labels: environment=aws, deployment-type=multi-node, node-count=2+
Cost: ~$100-250/month | Use Case: Production, high availability
```

## 🚀 Deployment Instructions

# 🏠 Local Environment (Minikube)

## Prerequisites
- Kubernetes 1.19+ (Minikube/Docker Desktop)
- Helm 3.8+
- Docker images built locally
- 4GB+ RAM, 2+ CPU cores

## Build Images
```bash
# From project root
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

# Load images into minikube
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0
```

## Deploy
```bash
# Install with default values
helm install resilience4j-stack ./helm/resilience4j-stack

# Install with custom values
helm install resilience4j-stack ./helm/resilience4j-stack -f custom-values.yaml
```

## Access Services
```bash
# Port forward to access services
kubectl port-forward svc/service-a 8080:8080
kubectl port-forward svc/prometheus 9090:9090
kubectl port-forward svc/grafana 3000:3000

# Test the application
curl http://localhost:8080/api/a/ok
curl http://localhost:8080/api/a/flaky?failRate=60
```

## Configuration
- **Namespace:** `default` or custom
- **Service A:** 1 replica
- **Service B:** 1 replica
- **Resources:** Minimal (development)
- **Cost:** Free
- **Use Case:** Development, learning

---

# ☁️ AWS Single Node Cluster

## Prerequisites
- AWS CLI configured
- eksctl installed
- Helm 3.8+
- ECR repositories (created automatically)
- IAM permissions for EKS and ECR

## Deploy
```bash
# 1. Deploy EKS cluster (automated)
./scripts/aws-deploy.sh resilience4j-dev 1 us-east-1

# 2. Manual Helm install (alternative)
helm install resilience4j-stack ./resilience4j-stack \
  -f ./environments/values-aws-single.yaml \
  --set serviceA.replicaCount=1 \
  --set serviceB.replicaCount=1
```

## Access Services
```bash
# Get ALB URL
kubectl get ingress -n resilience4j-aws-single

# Test via ALB
curl http://<ALB-URL>/api/a/ok

# Port forward for monitoring
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-aws-single
```

## Configuration
- **Namespace:** `resilience4j-aws-single`
- **Node Count:** 1 (t3.medium)
- **Service A:** 1 replica
- **Service B:** 1 replica
- **Autoscaling:** Basic HPA only
- **Cost:** ~$50/month
- **Use Case:** Development, testing, cost optimization

---

# ☁️ AWS Multi-Node Cluster

## Prerequisites
- AWS CLI configured
- eksctl installed
- Helm 3.8+
- ECR repositories (created automatically)
- IAM permissions for EKS, ECR, Auto Scaling

## Deploy
```bash
# 1. Deploy EKS cluster (automated)
./scripts/aws-deploy.sh resilience4j-prod 3 us-east-1

# 2. Manual Helm install with autoscaling
helm install resilience4j-stack ./resilience4j-stack \
  -f ./environments/values-aws-multi.yaml \
  --set serviceA.replicaCount=2 \
  --set serviceB.replicaCount=2 \
  --set autoscaling.hpa.enabled=true \
  --set autoscaling.vpa.enabled=true
```

## Access Services
```bash
# Get ALB URL
kubectl get ingress -n resilience4j-aws-multi

# Test via ALB
curl http://<ALB-URL>/api/a/ok

# Port forward for monitoring
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-aws-multi
```

## Configuration
- **Namespace:** `resilience4j-aws-multi`
- **Node Count:** 2-5 (t3.medium)
- **Service A:** 2+ replicas (distributed)
- **Service B:** 2+ replicas (distributed)
- **Autoscaling:** HPA + VPA + Cluster Autoscaler
- **Cost:** ~$100-250/month
- **Use Case:** Production, high availability, load testing

## ⚙️ Configuration

### Core Services Configuration

```yaml
# values.yaml
serviceA:
  enabled: true
  replicaCount: 2
  image:
    repository: r4j-sample-service-a
    tag: "0.1.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

serviceB:
  enabled: true
  replicaCount: 1
  image:
    repository: r4j-sample-service-b
    tag: "0.1.0"
```

### Monitoring Stack Configuration

```yaml
prometheus:
  enabled: true
  config:
    scrapeInterval: 15s
    evaluationInterval: 15s
  resources:
    requests:
      memory: "512Mi"
      cpu: "200m"

grafana:
  enabled: true
  adminUser: admin
  adminPassword: admin
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: resilience4j.local
      paths:
        - path: /
          pathType: Prefix
          service: service-a
  tls:
    - secretName: resilience4j-tls
      hosts:
        - resilience4j.local
```

---

# 📊 Monitoring

## Local Environment Monitoring
```bash
# Port forward to access monitoring
kubectl port-forward svc/grafana 3000:3000
kubectl port-forward svc/prometheus 9090:9090

# Access points
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090
```

## AWS Single Node Monitoring
```bash
# Port forward to access monitoring
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-aws-single
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-aws-single

# Load dashboards
cd ../grafana
./scripts/load-dashboards-k8s.sh resilience4j-aws-single single
```

## AWS Multi-Node Monitoring
```bash
# Port forward to access monitoring
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-aws-multi
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-aws-multi

# Load dashboards
cd ../grafana
./scripts/load-dashboards-k8s.sh resilience4j-aws-multi multi

# Monitor autoscaling
kubectl get hpa -n resilience4j-aws-multi -w
kubectl get vpa -n resilience4j-aws-multi -w
```

## Dashboard Setup

**Automatic Loading:**
```bash
# Load dashboards automatically
cd ../grafana
./scripts/load-dashboards-k8s.sh <namespace> <environment>
```

**Manual Import:**
1. Access Grafana at `http://localhost:3000` (admin/admin)
2. Add Prometheus data source: `http://prometheus:9090`
3. Import dashboard using ID `12139` or upload `grafana-dashboard-enhanced.json`

---

# 🔄 Autoscaling

## Local Environment (Optional)
```bash
# Enable basic HPA
helm upgrade resilience4j-stack ./resilience4j-stack \
  --set autoscaling.hpa.enabled=true

# Monitor scaling
kubectl get hpa -w
```

## AWS Single Node Autoscaling
```bash
# Enable HPA (limited by single node)
helm upgrade resilience4j-stack ./resilience4j-stack \
  --set autoscaling.hpa.enabled=true

# Monitor scaling
kubectl get hpa -n resilience4j-aws-single -w
kubectl top nodes
```
**Limitation:** Scaling limited to single node capacity

## AWS Multi-Node Autoscaling
```bash
# Enable full autoscaling
helm upgrade resilience4j-stack ./resilience4j-stack \
  --set autoscaling.hpa.enabled=true \
  --set autoscaling.vpa.enabled=true

# Monitor all scaling types
kubectl get hpa -n resilience4j-aws-multi -w
kubectl get vpa -n resilience4j-aws-multi -w
kubectl get nodes -w
```
**Features:** HPA + VPA + Cluster Autoscaler

## Configuration Examples

### HPA Configuration
```yaml
autoscaling:
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

### VPA Configuration
```yaml
autoscaling:
  vpa:
    enabled: true
    updateMode: "Auto"
    minAllowed:
      cpu: 100m
      memory: 128Mi
    maxAllowed:
      cpu: 2000m
      memory: 2Gi
```

### Key Metrics to Monitor

- `resilience4j_circuitbreaker_state` - Circuit breaker states
- `resilience4j_bulkhead_available_concurrent_calls` - Bulkhead capacity
- `resilience4j_retry_calls_total` - Retry attempts
- `resilience4j_ratelimiter_available_permissions` - Rate limiter status
- `http_server_requests_seconds_count` - HTTP request metrics

### ServiceMonitor for Prometheus Operator

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  scrapeTimeout: 10s
```

## 🔧 Advanced Configuration

### Custom Resource Limits

```yaml
# Production-ready resource configuration
serviceA:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

prometheus:
  resources:
    requests:
      memory: "2Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "1000m"
```

### High Availability Setup

```yaml
serviceA:
  replicaCount: 3
  
serviceB:
  replicaCount: 2

# Add pod disruption budgets
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### AWS ECR Configuration

```yaml
# Automatically configured by aws-deploy.sh
global:
  environment: aws
  imageRegistry: "123456789.dkr.ecr.us-east-1.amazonaws.com/"

serviceA:
  image:
    repository: r4j-sample-service-a
    tag: "0.1.0"
    pullPolicy: Always

# ALB Ingress
ingress:
  enabled: true
  className: "alb"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

### AWS Resource Configurations

**Single Node Configuration (values-aws-single.yaml):**
```yaml
# Optimized for single node deployment
serviceA:
  replicaCount: 1
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

serviceB:
  replicaCount: 1
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

# Disable autoscaling for single node
autoscaling:
  hpa:
    enabled: false
  vpa:
    enabled: false
```

**Multi-Node Configuration (values-aws-multi.yaml):**
```yaml
# Optimized for multi-node deployment
serviceA:
  replicaCount: 2
  resources:
    requests:
      memory: "512Mi"
      cpu: "300m"
    limits:
      memory: "1Gi"
      cpu: "800m"

serviceB:
  replicaCount: 2
  resources:
    requests:
      memory: "512Mi"
      cpu: "300m"
    limits:
      memory: "1Gi"
      cpu: "800m"

# Enable autoscaling for multi-node
autoscaling:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
  vpa:
    enabled: true
    updateMode: "Auto"

# Pod anti-affinity for node distribution
affinity:
  enabled: true
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - service-a
        topologyKey: kubernetes.io/hostname
```

## 🛠️ Management Commands

### Installation and Upgrades

```bash
# Install
helm install resilience4j-stack ./helm/resilience4j-stack

# Upgrade
helm upgrade resilience4j-stack ./helm/resilience4j-stack

# Rollback
helm rollback resilience4j-stack 1

# Uninstall
helm uninstall resilience4j-stack
```

### Debugging

```bash
# Check release status
helm status resilience4j-stack

# Get all resources
kubectl get all -l app.kubernetes.io/instance=resilience4j-stack

# Check pod logs
kubectl logs -l app.kubernetes.io/name=service-a
kubectl logs -l app=prometheus

# Describe problematic pods
kubectl describe pod <pod-name>
```

---

# 🧪 Testing

## Local Environment Testing
```bash
# Port forward Service A
kubectl port-forward svc/service-a 8080:8080

# Test endpoints
curl http://localhost:8080/api/a/ok
curl "http://localhost:8080/api/a/flaky?failRate=70"
curl "http://localhost:8080/api/a/slow?delayMs=3000"
curl http://localhost:8080/api/a/bulkhead/x
curl http://localhost:8080/api/a/limited
```

## AWS Single Node Testing
```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress -n resilience4j-aws-single -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Test via ALB
curl http://$ALB_URL/api/a/ok
curl "http://$ALB_URL/api/a/flaky?failRate=70"
```

## AWS Multi-Node Testing
```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress -n resilience4j-aws-multi -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Test with load
curl http://$ALB_URL/api/a/ok
curl "http://$ALB_URL/api/a/flaky?failRate=70"

# Test autoscaling
for i in {1..100}; do curl -s http://$ALB_URL/api/a/slow?delayMs=2000 & done
kubectl get hpa -n resilience4j-aws-multi -w
```

## NodeJS Client Testing
```bash
# From project root
cd ../nodejs-client
npm install

# Local testing
npm start

# AWS testing (update .env.aws with ALB URL)
npm run test:aws
npm run test:performance
```

## 🐛 Troubleshooting

### Common Issues

#### 1. ImagePullBackOff Error

**Problem**: Pods stuck in `ImagePullBackOff` state

**Solution**:
```bash
# Check if images exist locally (for Minikube)
minikube image ls | grep r4j-sample

# Load images if missing
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0

# Or build images in Minikube context
eval $(minikube docker-env)
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/
```

#### 2. Service Connection Issues

**Problem**: Service A cannot connect to Service B

**Solution**:
```bash
# Check service discovery
kubectl get svc
kubectl get endpoints

# Verify Service B is running
kubectl logs -l app.kubernetes.io/name=service-b

# Check network policies
kubectl get networkpolicies

# Test internal connectivity
kubectl exec -it <service-a-pod> -- curl http://service-b:8081/actuator/health
```

#### 3. Prometheus Not Scraping Metrics

**Problem**: No metrics appearing in Prometheus

**Solution**:
```bash
# Check Prometheus configuration
kubectl get configmap prometheus-config -o yaml

# Verify service endpoints
kubectl get endpoints service-a service-b

# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090
# Go to http://localhost:9090/targets

# Test metrics endpoints directly
kubectl exec -it <service-a-pod> -- curl http://localhost:8080/actuator/prometheus
```

#### 4. Grafana Dashboard Issues

**Problem**: Grafana shows no data or connection errors

**Solution**:
```bash
# Check Grafana logs
kubectl logs -l app=grafana

# Verify Prometheus data source
# URL should be: http://prometheus:9090

# Test Prometheus connectivity from Grafana pod
kubectl exec -it <grafana-pod> -- wget -qO- http://prometheus:9090/api/v1/query?query=up

# Import dashboard manually
# Use docker/dashboards/grafana-dashboard-enhanced.json
```

#### 5. Resource Constraints

**Problem**: Pods being killed or not starting due to resource limits

**Solution**:
```bash
# Check resource usage
kubectl top pods
kubectl describe nodes

# Adjust resource limits in values.yaml
serviceA:
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

# Apply changes
helm upgrade resilience4j-stack ./helm/resilience4j-stack
```

#### 6. Persistent Volume Issues

**Problem**: Prometheus losing data on restart

**Solution**:
```yaml
# Add persistent storage in values.yaml
prometheus:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: standard
```

### Diagnostic Commands

```bash
# Get all resources
kubectl get all -l app.kubernetes.io/instance=resilience4j-stack

# Check pod status and events
kubectl describe pods -l app.kubernetes.io/instance=resilience4j-stack

# View logs for all services
kubectl logs -l app.kubernetes.io/name=service-a --tail=100
kubectl logs -l app.kubernetes.io/name=service-b --tail=100
kubectl logs -l app=prometheus --tail=100
kubectl logs -l app=grafana --tail=100

# Check service connectivity
kubectl get svc,endpoints

# Verify ConfigMaps
kubectl get configmaps
kubectl describe configmap prometheus-config
kubectl describe configmap otel-collector-config

# Check resource usage
kubectl top pods
kubectl top nodes

# Network debugging
kubectl exec -it <pod-name> -- nslookup service-b
kubectl exec -it <pod-name> -- telnet service-b 8081
```

### Performance Tuning

```yaml
# Optimize for production
serviceA:
  replicaCount: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  
prometheus:
  config:
    scrapeInterval: 30s  # Reduce scrape frequency
  resources:
    requests:
      memory: "2Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "1000m"

# Add horizontal pod autoscaler
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

---

# 🧹 Cleanup

## Local Environment Cleanup
```bash
# Clean Helm release
./scripts/cleanup.sh resilience4j-stack default

# Clean all releases
./scripts/cleanup.sh --all

# Manual cleanup
helm uninstall resilience4j-stack

# Clean Docker images
docker rmi r4j-sample-service-a:0.1.0
docker rmi r4j-sample-service-b:0.1.0

# Windows users
scripts\cleanup.bat resilience4j-stack default
```

## AWS Single Node Cleanup
```bash
# Clean release only (keep cluster)
./scripts/cleanup.sh resilience4j-stack resilience4j-aws-single

# Full cleanup (includes EKS cluster)
./scripts/cleanup-aws.sh resilience4j-dev us-east-1
```

## AWS Multi-Node Cleanup
```bash
# Clean release only (keep cluster)
./scripts/cleanup.sh resilience4j-stack resilience4j-aws-multi

# Full cleanup (includes EKS cluster)
./scripts/cleanup-aws.sh resilience4j-prod us-east-1
```

## Cleanup Options

| Command | Scope | Description |
|---------|-------|-------------|
| `./scripts/cleanup.sh` | Single | Clean default release |
| `./scripts/cleanup.sh <release> <namespace>` | Single | Clean specific release |
| `./scripts/cleanup.sh --all` | All | Clean all releases |
| `./scripts/cleanup-aws.sh <cluster> <region>` | AWS Full | EKS + ECR + releases |

## 📚 Additional Resources

- [Resilience4j Documentation](https://resilience4j.readme.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.