# OpenTelemetry Dashboard

## 📊 Overview

A comprehensive Grafana dashboard for monitoring OpenTelemetry Collector performance and observability metrics in the Resilience4j sample application.

## 🎯 Dashboard Features

### OTel Collector Monitoring
- **Span Reception Rate**: Tracks accepted vs refused spans by receiver
- **Metric Reception Rate**: Monitors accepted vs refused metrics by receiver  
- **Span Export Rate**: Shows sent vs failed spans by exporter
- **Metric Export Rate**: Displays sent vs failed metrics by exporter
- **Memory Usage**: OTel Collector RSS memory consumption
- **CPU Usage**: Collector CPU utilization

### Application Observability
- **HTTP Request Duration**: P95/P99 latencies using OTel semantic conventions
- **HTTP Request Rate**: Request throughput with OTel labels (service_name, http_method, http_route, http_status_code)
- **Span Duration Distribution**: P95/P99 span processing times
- **Telemetry Generation**: Application-level traces and spans received

### Data Pipeline Health
- **Batch Processor Stats**: Average batch size and send rates
- **Data Drop Rate**: Percentage of spans/metrics dropped in processing
- **CPU Usage Comparison**: Cross-service CPU utilization (Collector vs Services)

## 🔧 Technical Details

### Compatibility
- **Grafana Version**: Schema version 38 (latest)
- **Prometheus**: Compatible with latest Prometheus versions
- **OTel Collector**: Supports standard OTel Collector metrics

### Metrics Used
```promql
# Collector Reception
otelcol_receiver_accepted_spans_total
otelcol_receiver_refused_spans_total
otelcol_receiver_accepted_metric_points_total
otelcol_receiver_refused_metric_points_total

# Collector Export
otelcol_exporter_sent_spans_total
otelcol_exporter_send_failed_spans_total
otelcol_exporter_sent_metric_points_total
otelcol_exporter_send_failed_metric_points_total

# Collector Performance
otelcol_process_memory_rss
otelcol_process_cpu_seconds_total
otelcol_processor_batch_batch_send_size_sum
otelcol_processor_batch_batch_send_size_count

# Application Metrics (OTel Semantic Conventions)
http_server_request_duration_seconds_bucket
http_server_requests_total
span_duration_milliseconds_bucket

# Data Quality
otelcol_processor_dropped_spans_total
otelcol_processor_dropped_metric_points_total
```

## 📁 File Locations

- **Main Dashboard**: `grafana/dashboards/grafana-dashboard-opentelemetry.json`
- **Docker Copy**: `docker/dashboards/grafana-dashboard-opentelemetry.json`

## 🚀 Usage

### Automatic Loading
The dashboard is automatically loaded by the existing dashboard loading scripts:

```bash
# Load all dashboards (includes OpenTelemetry)
cd grafana
./scripts/load-dashboards.sh

# Kubernetes environments
./scripts/load-dashboards-k8s.sh resilience4j-local local
```

### Manual Import
1. Access Grafana at http://localhost:3000 (admin/admin)
2. Go to Dashboards → Import
3. Upload `grafana-dashboard-opentelemetry.json`
4. Select Prometheus datasource

## 🎨 Dashboard Properties

- **Title**: OpenTelemetry Observability Dashboard
- **UID**: `otel-observability`
- **Tags**: `opentelemetry`, `otel`, `tracing`, `metrics`, `observability`
- **Refresh**: 5 seconds
- **Time Range**: Last 15 minutes
- **Theme**: Dark mode

## 📈 Key Insights

### What to Monitor
1. **Reception Health**: Ensure spans/metrics are being accepted, not refused
2. **Export Success**: Verify data is being successfully sent to backends
3. **Resource Usage**: Monitor Collector memory and CPU consumption
4. **Data Loss**: Watch for dropped spans/metrics indicating pipeline issues
5. **Application Performance**: Track request latencies and span durations

### Alerting Recommendations
- High refusal rates (>5%)
- Export failures (>1%)
- Memory usage growth trends
- High data drop rates (>0.1%)
- Collector CPU usage (>80%)

## 🔗 Integration

The dashboard integrates seamlessly with the existing monitoring stack:
- Uses the same Prometheus datasource as other dashboards
- Compatible with the automated loading scripts
- Follows the same visual design patterns
- Complements Resilience4j metrics with observability data

This dashboard provides comprehensive visibility into the OpenTelemetry pipeline health and application observability metrics.