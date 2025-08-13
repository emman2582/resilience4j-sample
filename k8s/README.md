# Resilience4j Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Resilience4j sample application with monitoring stack.

## Architecture

- **service-a**: Client-facing API with Resilience4j patterns (port 8080)
- **service-b**: Downstream API service (port 8081)
- **prometheus**: Metrics collection and storage (port 9090)
- **grafana**: Metrics visualization dashboard (port 3000)
- **otel-collector**: OpenTelemetry collector for traces/metrics (port 4318)

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Docker images available:
  - `r4j-sample-service-a:0.1.0`
  - `r4j-sample-service-b:0.1.0`

## Quick Start

1. **Deploy all services:**
   ```bash
   kubectl apply -f k8s/
   ```

2. **Check deployment status:**
   ```bash
   kubectl get pods
   kubectl get services
   ```

3. **Access applications:**
   ```bash
   # Port forward to access services locally
   kubectl port-forward svc/service-a 8080:8080 &
   kubectl port-forward svc/grafana 3000:3000 &
   kubectl port-forward svc/prometheus 9090:9090 &
   ```

4. **Test the application:**
   ```bash
   curl http://localhost:8080/api/a/ok
   curl http://localhost:8080/api/a/flaky?failRate=60
   ```

5. **Access monitoring:**
   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090

## Configuration Files

- `configs/`: ConfigMaps for Prometheus and OpenTelemetry Collector
- `deployments/`: Deployment manifests for all services
- `services/`: Service manifests for network access

## Cleanup

```bash
kubectl delete -f k8s/
```

## Notes

- All services are deployed in the default namespace
- ConfigMaps contain the same configurations as docker-compose setup
- Services use ClusterIP by default; use port-forward for local access
- For production, consider using Ingress controllers and persistent volumes