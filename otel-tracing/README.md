# OpenTelemetry Comprehensive Telemetry Collection

Instruments Service A and B with OpenTelemetry to collect metrics, traces, and logs using OTLP, HTTP, and Prometheus protocols.

## 🎯 Goal
Collect comprehensive telemetry data including:
- **Traces**: End-to-end transaction flows (Service A → Service B)
- **Metrics**: Request latencies, throughput, error rates, Resilience4j patterns
- **Logs**: Application logs with correlation IDs and structured logging
- **Infrastructure**: OTel Collector, Jaeger, Loki, and Prometheus metrics

## 🚀 Quick Start

### 1. Build OTel-Enabled Services
```bash
# Windows
.\build.bat

# Linux/Mac
./build.sh
```

### 2. Start OTel Stack
```bash
docker compose up -d
```

### 3. Generate Traces & Dashboard Data
```bash
# Quick dashboard test (2 minutes)
./test-dashboard-quick.sh     # Linux/Mac
.\test-dashboard-quick.bat    # Windows

# Comprehensive test (5 minutes)
./test-otel-comprehensive.sh  # Linux/Mac
.\test-otel-comprehensive.bat # Windows

# Basic trace test
./test-traces.sh              # Linux/Mac
```

### 4. View Results
- **Jaeger Traces**: http://localhost:16686
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Loki Logs**: http://localhost:3100
- **OTel Collector Metrics**: http://localhost:8888/metrics

## 📊 Telemetry Collection

### Traces
- End-to-end request flows with span correlation
- Distributed tracing across Service A → Service B
- Resilience4j pattern tracing (circuit breaker, retry, etc.)

### Metrics (OTLP + Prometheus)
- Request latencies (P50, P95, P99)
- Throughput and error rates
- Resilience4j pattern metrics
- JVM and application metrics
- OTel Collector internal metrics

### Logs (OTLP + File)
- Structured application logs
- Correlation with traces via trace/span IDs
- Log aggregation in Loki
- Real-time log streaming

## 🔧 Key Features

### Protocols & Standards
- **OTLP**: gRPC (4317) and HTTP (4318) for traces, metrics, logs
- **Prometheus**: Scraping application and infrastructure metrics
- **HTTP**: REST endpoints for health checks and custom metrics

### Telemetry Collection
- **Auto-Instrumentation**: OpenTelemetry Java agent with zero code changes
- **Distributed Tracing**: Complete request flows with correlation IDs
- **Metrics**: OTLP + Prometheus dual export for comprehensive coverage
- **Structured Logging**: File-based logs with trace correlation
- **Infrastructure Monitoring**: OTel Collector, Jaeger, Loki metrics

### Integrations
- **Jaeger**: Visual trace exploration and dependency mapping
- **Loki**: Log aggregation with trace correlation
- **Grafana**: Unified observability dashboard
- **Resilience4j**: Pattern-aware instrumentation

## 📁 Architecture

```
Client → Service A → Service B
   │         │         │
   │    Traces/Metrics/Logs
   │         │         │
   └─────────┴─────────┘
            │
     OTel Collector (OTLP/HTTP)
            │
    ┌───────┼────────┐
    │       │        │
  Jaeger   Loki   Prometheus
 (Traces) (Logs)  (Metrics)
    │       │        │
    └───────┼────────┘
            │
        Grafana
```

## 🧪 Test Scenarios

The test script generates traces for:
- Normal requests (`/api/a/ok`)
- Circuit breaker failures (`/api/a/flaky`)
- Timeout scenarios (`/api/a/slow`)
- Bulkhead isolation (`/api/a/bulkhead/*`)
- Rate limiting (`/api/a/limited`)

Each scenario creates distributed traces showing the complete request journey through both services.