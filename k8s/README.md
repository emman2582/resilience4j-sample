# Resilience4j Kubernetes Deployment

Kubernetes deployment for Resilience4j sample application with complete monitoring stack.

## 🏗️ Architecture

- **service-a**: Client API with Resilience4j patterns (8080)
- **service-b**: Downstream API service (8081)
- **prometheus**: Metrics collection and storage (9090)
- **grafana**: Visualization dashboard (3000)
- **otel-collector**: OpenTelemetry collector (4318 OTLP, 9464 metrics)

## 📋 Prerequisites

### Local Development
- Minikube or Docker Desktop Kubernetes
- kubectl configured
- Local Docker images built:
  ```bash
  gradle clean build
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

## 🚀 Quick Deployment

### Local Development (Minikube)

1. **Load local images:**
   ```bash
   cd k8s
   chmod +x *.sh
   ./load-images.sh
   ```

2. **Deploy all services:**
   ```bash
   ./deploy.sh
   ```

3. **Setup port forwarding:**
   ```bash
   ./port-forward.sh
   ```

### AWS Cloud Deployment

**Single Node Cluster:**
```bash
# Deploy single node EKS cluster
./aws-deploy.sh resilience4j-cluster 1 us-east-1
```

**Multi Node Cluster:**
```bash
# Deploy 2-node EKS cluster
./aws-deploy.sh resilience4j-cluster 2 us-east-1
```

**Check Status:**
```bash
./check-status.sh
kubectl get ingress  # Get ALB URL
```

## 🧪 Testing

**Using cURL:**
```bash
# Test basic connectivity
curl http://localhost:8080/api/a/ok

# Test resilience patterns
curl "http://localhost:8080/api/a/flaky?failRate=60"
curl "http://localhost:8080/api/a/slow?delayMs=2500"
curl http://localhost:8080/api/a/bulkhead/x
curl http://localhost:8080/api/a/limited
```

**Using NodeJS Client:**
```bash
# From project root
cd ../nodejs-client
npm install
npm start                    # Test all endpoints
npm run test:performance     # Load testing
```

## 📊 Monitoring Access

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Service A Metrics**: http://localhost:8080/actuator/prometheus
- **Service B Metrics**: http://localhost:8081/actuator/prometheus
- **OTel Collector Metrics**: http://localhost:9464/metrics

### Auto-Load Dashboards
```bash
# Load enhanced and golden metrics dashboards
cd grafana
./load-dashboards-k8s.sh resilience4j-local local
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
./load-images.sh
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
# Kill existing port forwards
pkill -f "kubectl port-forward"

# Check pod status first
kubectl get pods
./check-status.sh

# Use pod name instead of service
kubectl port-forward pod/<pod-name> 8080:8080

# Check for port conflicts
netstat -an | findstr :8080
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

# Increase CPU limits
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

## 📁 Project Structure

```
k8s/
├── configs/           # ConfigMaps for Prometheus & OTel
├── deployments/       # Pod deployments
├── services/          # Network services
├── deploy.sh          # Main deployment script
├── check-status.sh    # Status checking
├── port-forward.sh    # Port forwarding setup
├── load-images.sh     # Load images to minikube
├── fix-deployment.sh  # Reset and fix deployment
└── cleanup.sh         # Remove all resources
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