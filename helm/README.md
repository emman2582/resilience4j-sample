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

### AWS Single Node
```
Namespace: resilience4j-aws-single
Helm Chart → EKS (1 node) → ALB Ingress → Services (1 replica each)
Labels: environment=aws, deployment-type=single-node, node-count=1
```

### AWS Multi Node
```
Namespace: resilience4j-aws-multi
Helm Chart → EKS (2 nodes) → ALB Ingress → Services (2 replicas each)
Labels: environment=aws, deployment-type=multi-node, node-count=2
```

## 🚀 Quick Start

### 1. Build Docker Images

```bash
# From project root
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

# For Minikube, load images into cluster
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0
```

### 2. Install the Chart

**Local Development (Minikube):**
```bash
# Install with default values
helm install resilience4j-stack ./helm/resilience4j-stack

# Install with custom values
helm install resilience4j-stack ./helm/resilience4j-stack -f custom-values.yaml
```

**AWS Cloud Deployment:**
```bash
# Single node EKS cluster
./helm/aws-deploy.sh resilience4j-cluster 1 us-east-1

# Multi-node EKS cluster  
./helm/aws-deploy.sh resilience4j-cluster 2 us-east-1

# Manual Helm install with AWS values
helm install resilience4j-stack ./helm/resilience4j-stack \
  -f ./helm/resilience4j-stack/values-aws-single.yaml
```

### 3. Access Services

```bash
# Port forward to access services locally
kubectl port-forward svc/service-a 8080:8080
kubectl port-forward svc/prometheus 9090:9090
kubectl port-forward svc/grafana 3000:3000

# Test the application
curl http://localhost:8080/api/a/ok
curl http://localhost:8080/api/a/flaky?failRate=60
```

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

## 📊 Monitoring Setup

### Grafana Dashboard Setup

**Automatic Loading:**
```bash
# Load dashboards automatically
cd grafana
./load-dashboards-k8s.sh resilience4j-local local
```

**Manual Import:**
1. Access Grafana at `http://localhost:3000` (admin/admin)
2. Add Prometheus data source: `http://prometheus:9090`
3. Import dashboard using ID `12139` or upload `grafana-dashboard-enhanced.json`

## 🔄 Autoscaling

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

### Deploy with Autoscaling
```bash
# Enable HPA only
helm install resilience4j-stack ./resilience4j-stack \
  --set autoscaling.hpa.enabled=true

# Enable both HPA and VPA
helm install resilience4j-stack ./resilience4j-stack \
  --set autoscaling.hpa.enabled=true \
  --set autoscaling.vpa.enabled=true
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

**Single Node (values-aws-single.yaml):**
```yaml
serviceA:
  replicaCount: 1
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

**Multi Node (values-aws-multi.yaml):**
```yaml
serviceA:
  replicaCount: 2
  resources:
    requests:
      memory: "512Mi"
      cpu: "300m"
    limits:
      memory: "1Gi"
      cpu: "800m"

# Pod anti-affinity for node distribution
affinity:
  enabled: true
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

### Testing Resilience Patterns

**Using cURL:**
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

**Using NodeJS Client:**
```bash
# From project root (with port forwarding active)
cd ../nodejs-client
npm install
npm start                    # Test all endpoints
npm run test:performance     # Load testing
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
# Use grafana-dashboard-enhanced.json from project root
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

## 🧹 Cleanup

### Local Development
```bash
# Uninstall Helm release
helm uninstall resilience4j-stack

# Clean up Docker images
docker rmi r4j-sample-service-a:0.1.0
docker rmi r4j-sample-service-b:0.1.0
```

### AWS Cloud
```bash
# Uninstall Helm release
helm uninstall resilience4j-stack

# Delete EKS cluster
eksctl delete cluster --name resilience4j-cluster --region us-east-1

# Clean up ECR repositories (optional)
aws ecr delete-repository --repository-name r4j-sample-service-a --region us-east-1 --force
aws ecr delete-repository --repository-name r4j-sample-service-b --region us-east-1 --force

# Remove persistent volumes
kubectl get pv
kubectl delete pv <pv-name>
```

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