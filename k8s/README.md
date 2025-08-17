# Resilience4j Kubernetes Deployment

Kubernetes deployment for Resilience4j sample application with complete monitoring stack.

## 🏗️ Architecture

- **service-a**: Client API with Resilience4j patterns (8080)
- **service-b**: Downstream API service (8081)
- **prometheus**: Metrics collection and storage (9090)
- **grafana**: Visualization dashboard (3000)
- **otel-collector**: OpenTelemetry collector (4318 OTLP, 9464 metrics)
- **minikube-dashboard**: Kubernetes cluster management UI

## 📋 Prerequisites

### Local Development
- Minikube or Docker Desktop Kubernetes
- kubectl configured
- Local Docker images built:
  ```bash
  # From project root directory (not k8s/)
  cd ..
  ./gradlew clean build
  docker build -t r4j-sample-service-a:0.1.0 service-a/
  docker build -t r4j-sample-service-b:0.1.0 service-b/
  ```

### AWS Cloud
- AWS CLI configured
- eksctl installed
- kubectl installed
- Docker for building images
- ECR repositories (created automatically)

## 🏗️ Deployment Architectures

### Local (Minikube)
```
Namespace: resilience4j-local
NodeJS Client → Port Forward → Service A → Service B
Labels: environment=local, deployment-type=minikube
```

### AWS Single Node
```
Namespace: resilience4j-aws-single
NodeJS Client → ALB → EKS (1 node) → Service A → Service B
Labels: environment=aws, deployment-type=single-node, node-count=1
```

### AWS Multi Node
```
Namespace: resilience4j-aws-multi
NodeJS Client → ALB → EKS (2 nodes) → Service A (2 replicas) → Service B (2 replicas)
Labels: environment=aws, deployment-type=multi-node, node-count=2
```

## 🚀 Deployment Instructions

### 🏠 Local Environment (Minikube)

**Prerequisites:**
- Minikube installed and running
- kubectl configured for minikube
- Docker Desktop running

**Deployment Steps:**
```bash
cd k8s

# 0. Start minikube with required addons
./scripts/start-minikube.sh

# 1. Build Docker images from source
./scripts/build-images.sh

# 2. Load images into minikube
./scripts/load-images.sh

# 3. Deploy all services to Kubernetes
./scripts/deploy.sh

# 4. Setup port forwarding daemon (returns terminal control)
./scripts/port-forward.sh

# 5. Load Grafana dashboards
./scripts/load-dashboards.sh resilience4j-local

# Optional: Access Minikube dashboard
cd ../k8s
minikube dashboard
```

**Management Commands:**
```bash
# Check port forwarding status
./scripts/status-port-forward.sh

# Stop port forwarding
./scripts/stop-port-forward.sh

# Force cleanup if ports are stuck
./scripts/port-forward.sh --force

# Check deployment status
./scripts/check-status.sh

# Cleanup everything
./scripts/cleanup.sh
```

**Access Points (after port forwarding is active):**
- **Service A**: http://localhost:8080
- **Service B**: http://localhost:8081  
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **OTel Collector**: http://localhost:9464/metrics
- **Minikube Dashboard**: `minikube dashboard`

---

### ☁️ AWS Single Node Deployment

**Prerequisites:**
- AWS CLI configured
- eksctl installed
- kubectl installed

**Deployment Steps:**
```bash
cd k8s

# 1. Deploy EKS cluster (single node)
./scripts/aws-deploy.sh resilience4j-cluster 1 us-east-1

# 2. Check deployment status
./scripts/check-status.sh

# 3. Get ALB URL
kubectl get ingress -n resilience4j-aws-single

# 4. Load Grafana dashboards
./scripts/load-dashboards.sh resilience4j-aws-single
```

**Configuration:**
- Namespace: `resilience4j-aws-single`
- Node Count: 1
- Service A Replicas: 1
- Service B Replicas: 1

---

### ☁️ AWS Multi Node Deployment

**Prerequisites:**
- AWS CLI configured
- eksctl installed
- kubectl installed

**Deployment Steps:**
```bash
cd k8s

# 1. Deploy EKS cluster (multi node)
./scripts/aws-deploy.sh resilience4j-cluster 2 us-east-1

# 2. Check deployment status
./scripts/check-status.sh

# 3. Get ALB URL
kubectl get ingress -n resilience4j-aws-multi

# 4. Setup autoscaling (optional)
./scripts/setup-autoscaling.sh resilience4j-aws-multi

# 5. Load Grafana dashboards
./scripts/load-dashboards.sh resilience4j-aws-multi
```

**Configuration:**
- Namespace: `resilience4j-aws-multi`
- Node Count: 2
- Service A Replicas: 2
- Service B Replicas: 2
- Autoscaling: Enabled (HPA + VPA)

## 🧪 Testing

### Local Environment Testing
```bash
# Test basic connectivity
curl http://localhost:8080/api/a/ok

# Test resilience patterns
curl "http://localhost:8080/api/a/flaky?failRate=60"
curl "http://localhost:8080/api/a/slow?delayMs=2500"
curl http://localhost:8080/api/a/bulkhead/x
curl http://localhost:8080/api/a/limited
```

### AWS Environment Testing
```bash
# Get ALB URL first
ALB_URL=$(kubectl get ingress -n resilience4j-aws-single -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$ALB_URL/api/a/ok
curl "http://$ALB_URL/api/a/flaky?failRate=60"
curl "http://$ALB_URL/api/a/slow?delayMs=2500"
```

### NodeJS Client Testing
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

## 📊 Monitoring Access

### Local Environment
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Service A**: http://localhost:8080/actuator/prometheus
- **Service B**: http://localhost:8081/actuator/prometheus
- **OTel Collector**: http://localhost:9464/metrics

### Port Forwarding Management
```bash
# Check status
./scripts/status-port-forward.sh

# Stop daemon
./scripts/stop-port-forward.sh

# Restart with force cleanup
./scripts/port-forward.sh --force

# Run in foreground (for debugging)
./scripts/port-forward.sh foreground
```

### Minikube Dashboard
```bash
# Dashboard is auto-enabled by start-minikube.sh
# Access dashboard (opens in browser)
minikube dashboard

# Get dashboard URL without opening browser
minikube dashboard --url
```

### AWS Environment
```bash
# Port forward to access monitoring
kubectl port-forward svc/grafana 3000:3000 -n resilience4j-aws-single
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-aws-single
```

### Dashboard Loading
```bash
# Local
./scripts/load-dashboards.sh resilience4j-local

# AWS Single Node  
./scripts/load-dashboards.sh resilience4j-aws-single

# AWS Multi Node
./scripts/load-dashboards.sh resilience4j-aws-multi
```

## 🔄 Autoscaling

### Local Environment (Optional)
```bash
# Setup HPA only
./scripts/setup-autoscaling.sh resilience4j-local

# Test autoscaling
./scripts/test-autoscaling.sh resilience4j-local

# Monitor scaling
kubectl get hpa -n resilience4j-local -w
```

### AWS Single Node
```bash
# Setup basic autoscaling
./scripts/setup-autoscaling.sh resilience4j-aws-single

# Monitor scaling
kubectl get hpa -n resilience4j-aws-single -w
```

### AWS Multi Node (Recommended)
```bash
# Setup HPA + VPA (included in deployment)
./scripts/setup-autoscaling.sh resilience4j-aws-multi true

# Test scaling under load
./scripts/test-autoscaling.sh resilience4j-aws-multi

# Monitor scaling
kubectl get hpa -n resilience4j-aws-multi -w
kubectl get vpa -n resilience4j-aws-multi -w
```

## 🛠️ Troubleshooting

### Kubernetes Cluster Issues

**kubectl not connecting:**
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# For minikube
minikube status
minikube start  # If stopped

# Reset kubectl context
kubectl config get-contexts
kubectl config use-context <context-name>
```

**Minikube issues:**
```bash
# Restart minikube
minikube stop
minikube start

# Check minikube logs
minikube logs

# Increase resources
minikube start --memory=4096 --cpus=2
```

### Pod Issues

**Pods stuck in Pending:**
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check pod events
kubectl describe pod <pod-name>

# Check resource requests/limits
kubectl get pods -o yaml
```

**Pods in CrashLoopBackOff:**
```bash
# Check pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Check liveness/readiness probes
kubectl describe pod <pod-name>

# Disable probes temporarily for debugging
```

**ImagePullBackOff errors:**
```bash
# For minikube - load local images
./scripts/load-images.sh
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0

# Check if images exist
minikube image ls | grep r4j-sample
docker images | grep r4j-sample

# Verify imagePullPolicy is set to Never
kubectl get deployment <deployment-name> -o yaml | grep imagePullPolicy
```

### Service and Networking Issues

**Services not accessible:**
```bash
# Check service endpoints
kubectl get endpoints
kubectl describe service <service-name>

# Test internal connectivity
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod: wget -qO- http://service-a:8080/actuator/health
```

**Port forwarding fails:**
```bash
# Use the dedicated stop script
./scripts/stop-port-forward.sh

# Force cleanup stuck ports
./scripts/port-forward.sh --force

# Check port forwarding status
./scripts/status-port-forward.sh

# Manual cleanup if needed
pkill -9 -f "kubectl port-forward"

# Check what's using ports
netstat -an | findstr :8080  # Windows
lsof -i :8080               # Linux/Mac
```

### ConfigMap Issues

**Configuration not loading:**
```bash
# Check ConfigMap exists
kubectl get configmaps
kubectl describe configmap prometheus-config

# Verify volume mounts
kubectl describe pod <pod-name> | grep -A 10 "Mounts:"

# Check file inside pod
kubectl exec <pod-name> -- cat /etc/prometheus/prometheus.yml
```

### Resource Issues

**Out of memory errors:**
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Increase memory limits in deployment
# resources:
#   limits:
#     memory: "1Gi"
#   requests:
#     memory: "512Mi"
```

**CPU throttling:**
```bash
# Check CPU metrics
kubectl top pods

# Increase CPU limits in deployment YAML
# resources:
#   limits:
#     cpu: "1000m"
#   requests:
#     cpu: "500m"
```

### Application-Specific Issues

**Service A can't reach Service B:**
```bash
# Check service discovery
kubectl get services -n resilience4j-local
nslookup service-b  # From inside a pod

# Verify environment variables
kubectl exec <service-a-pod> -n resilience4j-local -- env | grep B_URL

# Test connectivity
kubectl exec <service-a-pod> -n resilience4j-local -- curl http://service-b:8081/actuator/health
```

**Metrics not appearing:**
```bash
# Check if actuator endpoints are exposed
kubectl exec <pod-name> -n resilience4j-local -- curl localhost:8080/actuator/prometheus

# Verify Prometheus scraping
kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-local
# Go to http://localhost:9090/targets
```

## 📁 Complete Project Structure

```
k8s/
├── environments/              # Environment-specific configurations
│   ├── namespace-local.yaml    # Local namespace definition
│   ├── namespace-aws-single.yaml # AWS single node namespace
│   ├── namespace-aws-multi.yaml  # AWS multi node namespace
│   ├── values-aws-single.yaml   # AWS single node values
│   └── values-aws-multi.yaml    # AWS multi node values
├── manifests/                 # Kubernetes manifests
│   ├── autoscaling/           # HPA and VPA configurations
│   │   ├── hpa-service-a.yaml # Horizontal Pod Autoscaler
│   │   ├── metrics-server.yaml # Metrics server for HPA
│   │   └── vpa-service-a.yaml  # Vertical Pod Autoscaler
│   ├── configs/               # ConfigMaps
│   │   ├── otel-collector-config.yaml # OpenTelemetry config
│   │   └── prometheus-config.yaml     # Prometheus scraping config
│   ├── deployments/           # Pod deployments
│   │   ├── grafana.yaml       # Grafana deployment
│   │   ├── otel-collector.yaml # OpenTelemetry collector
│   │   ├── prometheus.yaml    # Prometheus deployment
│   │   ├── service-a.yaml     # Service A deployment
│   │   └── service-b.yaml     # Service B deployment
│   └── services/              # Network services
│       ├── grafana.yaml       # Grafana service
│       ├── otel-collector.yaml # OTel collector service
│       ├── prometheus.yaml    # Prometheus service
│       ├── service-a.yaml     # Service A service
│       └── service-b.yaml     # Service B service
├── scripts/                   # All deployment and management scripts
│   ├── start-minikube.sh      # Start and configure minikube
│   ├── build-images.sh        # Build Docker images
│   ├── load-images.sh         # Load images to minikube
│   ├── deploy.sh              # Deploy all services
│   ├── port-forward.sh        # Port forwarding daemon
│   ├── stop-port-forward.sh   # Stop port forwarding
│   ├── status-port-forward.sh # Check port forwarding status
│   ├── check-status.sh        # Check deployment status
│   ├── setup-autoscaling.sh   # Setup HPA/VPA
│   ├── test-autoscaling.sh    # Test autoscaling
│   ├── aws-deploy.sh          # AWS EKS deployment
│   ├── aws-cleanup.sh         # AWS cleanup
│   ├── cleanup.sh             # Local cleanup
│   ├── diagnose-build.sh      # Diagnose build issues
│   ├── fix-deployment.sh      # Fix deployment issues
│   └── fix-minikube.sh        # Fix minikube issues
└── README.md                  # This documentation
```

## 🚀 Quick Start Summary

```bash
# Complete local deployment
cd k8s
./scripts/start-minikube.sh     # Start minikube with addons
./scripts/build-images.sh       # Build from source
./scripts/load-images.sh        # Load into minikube
./scripts/deploy.sh             # Deploy all services
./scripts/port-forward.sh       # Start port forwarding daemon

# Load dashboards
./scripts/load-dashboards.sh resilience4j-local

# Access services
# - Service A: http://localhost:8080
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
# - Minikube Dashboard: minikube dashboard

# Cleanup when done
cd ../k8s
./scripts/stop-port-forward.sh  # Stop port forwarding
./scripts/cleanup.sh            # Remove all resources
```resources:
#   limits:
#     cpu: "1000m"
#   requests:
#     cpu: "500m"
```

### Application-Specific Issues

**Service A can't reach Service B:**
```bash
# Check service discovery
kubectl get services
nslookup service-b  # From inside a pod

# Verify environment variables
kubectl exec <service-a-pod> -- env | grep B_URL

# Test connectivity
kubectl exec <service-a-pod> -- curl http://service-b:8081/actuator/health
```

**Metrics not appearing:**
```bash
# Check if actuator endpoints are exposed
kubectl exec <pod-name> -- curl localhost:8080/actuator/prometheus

# Verify Prometheus scraping
kubectl port-forward svc/prometheus 9090:9090
# Go to http://localhost:9090/targets
```

**OpenTelemetry Collector issues:**
```bash
# Check collector logs
kubectl logs deployment/otel-collector

# Verify configuration
kubectl get configmap otel-collector-config -o yaml

# Test collector endpoints
kubectl exec <otel-collector-pod> -- curl localhost:9464/metrics
```

### Debugging Commands

**Get detailed pod information:**
```bash
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> --follow
```

**Check resource usage:**
```bash
kubectl top pods
kubectl top nodes
```

**Debug networking:**
```bash
# Create debug pod
kubectl run debug --image=busybox --rm -it -- sh

# Test DNS resolution
nslookup service-a
nslookup prometheus

# Test connectivity
wget -qO- http://service-a:8080/actuator/health
```

**Force pod restart:**
```bash
# Delete pod (will be recreated)
kubectl delete pod <pod-name>

# Restart deployment
kubectl rollout restart deployment/<deployment-name>

# Scale down and up
kubectl scale deployment <deployment-name> --replicas=0
kubectl scale deployment <deployment-name> --replicas=1
```

### Common Error Solutions

**"no such host" errors:**
- Check service names match deployment labels
- Verify services are in same namespace
- Use FQDN: `service-name.namespace.svc.cluster.local`

**"connection refused" errors:**
- Check if pods are running and ready
- Verify port numbers in service definitions
- Check firewall/security group rules

**"image not found" errors:**
- Load images into minikube: `./load-images.sh`
- Set `imagePullPolicy: Never` for local images
- Check image names and tags match exactly

**"insufficient resources" errors:**
- Reduce resource requests in deployments
- Add more nodes to cluster
- Use minikube with more resources

## 🧹 Cleanup

### Local Environment
```bash
cd k8s
./scripts/cleanup.sh
```

### AWS Single Node
```bash
cd k8s
./scripts/aws-cleanup.sh resilience4j-cluster us-east-1
```

### AWS Multi Node
```bash
cd k8s
./scripts/aws-cleanup.sh resilience4j-cluster us-east-1
```

## 📁 Project Structure

```
k8s/
├── environments/      # Environment-specific configurations
│   ├── namespace-local.yaml
│   ├── namespace-aws-single.yaml
│   ├── namespace-aws-multi.yaml
│   ├── values-aws-single.yaml
│   └── values-aws-multi.yaml
├── manifests/         # Kubernetes manifests
│   ├── autoscaling/   # HPA and VPA configurations
│   ├── configs/       # ConfigMaps for Prometheus & OTel
│   ├── deployments/   # Pod deployments
│   └── services/      # Network services
├── scripts/           # All deployment and management scripts
│   ├── start-minikube.sh  # Start and configure minikube
│   ├── build-images.sh    # Build Docker images
│   ├── load-images.sh     # Load images to minikube
│   ├── deploy.sh          # Local deployment
│   ├── port-forward.sh    # Port forwarding setup
│   ├── aws-deploy.sh      # AWS deployment
│   ├── check-status.sh    # Check deployment status
│   ├── setup-autoscaling.sh # Setup HPA/VPA
│   ├── test-autoscaling.sh  # Test autoscaling
│   ├── cleanup.sh         # Local cleanup
│   └── aws-cleanup.sh     # AWS cleanup
└── README.md          # This file
```ove all resources
│   ├── aws-deploy.sh  # AWS EKS deployment
│   └── port-forward.sh # Port forwarding setup
├── environments/      # Environment-specific configurations
│   ├── namespace-*.yaml # Namespace definitions
│   └── values-*.yaml   # Environment values
└── README.md          # Documentation
```

## 🧹 Cleanup

### Local (Minikube)
```bash
./cleanup.sh
```

### AWS Cloud
```bash
# Clean up EKS cluster and resources
./aws-cleanup.sh resilience4j-cluster us-east-1

# Or manual cleanup
kubectl delete ingress --all
helm uninstall resilience4j-stack
eksctl delete cluster --name resilience4j-cluster --region us-east-1
```

## 📝 Notes

- Uses `imagePullPolicy: Never` for local development
- All services deployed in default namespace
- Health checks configured for better reliability
- Resource limits set for cluster stability