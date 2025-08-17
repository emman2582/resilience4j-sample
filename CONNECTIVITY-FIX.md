# Connectivity Configuration Summary

## Issues Fixed:

### 1. Service A Configuration
- **Problem**: Hardcoded `localhost:8081` for Service B URL
- **Fix**: Use environment variable `${B_URL:http://localhost:8081}`
- **File**: `service-a/src/main/resources/application.yml`

### 2. Kubernetes Deployments
- **Status**: ✅ CORRECT
- Service A deployment sets `B_URL=http://service-b:8081`
- Service names match between deployments and services
- Labels are consistent: `app: service-a`, `app: service-b`

### 3. Docker Compose
- **Status**: ✅ CORRECT  
- Service A sets `B_URL=http://service-b:8081`
- Container names match service names
- All services use `r4j-net` network

### 4. Prometheus Configuration
- **Status**: ✅ CORRECT
- K8s: Uses service names (`service-a:8080`, `service-b:8081`)
- Docker: Uses service names (`service-a:8080`, `service-b:8081`)

### 5. Grafana Datasource
- **Problem**: Used `localhost:9090` causing IPv6 issues
- **Fix**: Updated scripts to use `http://prometheus:9090`
- **Files**: `k8s/scripts/load-dashboards.sh`, `k8s/scripts/load-dashboards.bat`

### 6. Helm Charts
- **Status**: ✅ CORRECT
- Service A template uses `{{ .Values.serviceA.env.B_URL | quote }}`
- Values.yaml sets `B_URL: "http://service-b:8081"`

### 7. AWS Lambda
- **Status**: ✅ CORRECT
- Service A uses `SERVICE_B_URL=http://service-b:8080`
- Container networking configured properly

### 8. NodeJS Client
- **Status**: ✅ CORRECT
- Local: `SERVICE_A_URL=http://localhost:8080`
- AWS: Placeholder for API Gateway URL

## Environment-Specific Hostnames:

| Environment | Service A → Service B | Grafana → Prometheus | Client → Service A |
|-------------|----------------------|---------------------|-------------------|
| Local Dev   | `localhost:8081`     | `prometheus:9090`   | `localhost:8080`  |
| Docker      | `service-b:8081`     | `prometheus:9090`   | `localhost:8080`  |
| Kubernetes  | `service-b:8081`     | `prometheus:9090`   | `localhost:8080` (via port-forward) |
| Helm        | `service-b:8081`     | `prometheus:9090`   | `localhost:8080` (via port-forward) |
| AWS Lambda  | `service-b:8080`     | N/A                 | API Gateway URL   |

## Key Fixes Applied:
1. ✅ Service A now uses environment variable for Service B URL
2. ✅ Grafana scripts use correct Prometheus service name
3. ✅ All labels and selectors are consistent across deployments
4. ✅ Service names match between deployments, services, and configurations