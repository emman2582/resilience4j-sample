# Resilience4j Kubernetes Deployment

Kubernetes deployment for Resilience4j sample application with complete monitoring stack.

## 🏗️ Architecture

- **service-a**: Client API with Resilience4j patterns (8080)
- **service-b**: Downstream API service (8081)
- **prometheus**: Metrics collection and storage (9090)
- **grafana**: Visualization dashboard (3000)
- **otel-collector**: OpenTelemetry collector (4318 OTLP, 9464 metrics)

## 📋 Prerequisites

- Kubernetes cluster (minikube recommended for local development)
- kubectl configured and connected
- Local Docker images built:
  ```bash
  gradle clean build
  docker build -t r4j-sample-service-a:0.1.0 service-a/
  docker build -t r4j-sample-service-b:0.1.0 service-b/
  ```

## 🚀 Quick Deployment

1. **For Minikube users (load local images first):**
   ```bash
   cd k8s
   chmod +x *.sh
   ./load-images.sh
   ```

2. **Deploy all services:**
   ```bash
   ./deploy.sh
   ```

3. **Check deployment status:**
   ```bash
   ./check-status.sh
   ```

4. **Setup port forwarding:**
   ```bash
   ./port-forward.sh
   ```

## 🧪 Testing

```bash
# Test basic connectivity
curl http://localhost:8080/api/a/ok

# Test resilience patterns
curl "http://localhost:8080/api/a/flaky?failRate=60"
curl "http://localhost:8080/api/a/slow?delayMs=2500"
curl http://localhost:8080/api/a/bulkhead/x
curl http://localhost:8080/api/a/limited
```

## 📊 Monitoring Access

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Service A Metrics**: http://localhost:8080/actuator/prometheus
- **Service B Metrics**: http://localhost:8081/actuator/prometheus
- **OTel Collector Metrics**: http://localhost:9464/metrics

## 🛠️ Troubleshooting

**Pod not starting:**
```bash
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

**Image pull issues:**
```bash
./load-images.sh  # For minikube
# Or use ./fix-deployment.sh for complete reset
```

**Port forward issues:**
```bash
pkill -f "kubectl port-forward"
./port-forward.sh
```

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

```bash
./cleanup.sh
```

## 📝 Notes

- Uses `imagePullPolicy: Never` for local development
- All services deployed in default namespace
- Health checks configured for better reliability
- Resource limits set for cluster stability