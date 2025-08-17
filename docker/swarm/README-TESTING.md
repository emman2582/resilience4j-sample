# Autoscaler Testing Guide

## 🧪 How to Test the Autoscaler Implementation

### Prerequisites
1. Docker Swarm initialized: `./setup-swarm.sh`
2. Stack deployed with services running
3. Prometheus accessible at http://localhost:9090
4. Python installed for autoscaler

### Testing Methods

## 1. Automated Testing
```bash
# Run comprehensive test suite
./test-autoscaler.sh
```

## 2. Manual Testing

### Step 1: Start the Autoscaler
```bash
# Terminal 1 - Start autoscaler
./start-autoscaler.sh
```

### Step 2: Monitor Current State
```bash
# Terminal 2 - Monitor services
watch "docker service ls | grep service-a"

# Check Prometheus metrics
curl "http://localhost:9090/api/v1/query?query=up"
```

### Step 3: Generate Load (Scale-Up Test)
```bash
# Generate high CPU/memory load
./test-scaling.sh

# Or manual load generation
for i in {1..10}; do
  curl "http://localhost/api/a/slow?delayMs=2000" &
  curl "http://localhost/api/a/flaky?failRate=50" &
done
```

### Step 4: Verify Scale-Up
- Watch autoscaler logs for scaling decisions
- Monitor replica count: `docker service ls`
- Check scaling events: `docker service ps r4j-stack_service-a`

### Step 5: Test Scale-Down
```bash
# Stop load generators
pkill -f "curl.*localhost"

# Wait for scale-down (5 minute cooldown)
# Monitor replica reduction
```

## 3. Configuration Testing

### Autoscaler Settings
- **CPU Threshold**: 70% (scale up), 35% (scale down)
- **Memory Threshold**: 80% (scale up), 40% (scale down)
- **Min Replicas**: 1
- **Max Replicas**: 5
- **Scale Up Cooldown**: 60 seconds
- **Scale Down Cooldown**: 300 seconds

### Test Different Scenarios
```bash
# Test max scaling
# Generate extreme load to reach 5 replicas

# Test min scaling
# Remove all load to scale down to 1 replica

# Test cooldown periods
# Verify scaling doesn't happen too frequently
```

## 4. Monitoring Commands

### Service Status
```bash
# List all services
docker service ls

# Detailed service info
docker service ps r4j-stack_service-a

# Service logs
docker service logs r4j-stack_service-a
```

### Prometheus Queries
```bash
# CPU usage
curl "http://localhost:9090/api/v1/query?query=rate(container_cpu_usage_seconds_total[5m])*100"

# Memory usage
curl "http://localhost:9090/api/v1/query?query=container_memory_usage_bytes/container_spec_memory_limit_bytes*100"

# Service replicas
docker service inspect r4j-stack_service-a --format='{{.Spec.Mode.Replicated.Replicas}}'
```

## 5. Expected Behavior

### Scale-Up Triggers
- CPU usage > 70%
- Memory usage > 80%
- At least 60 seconds since last scaling

### Scale-Down Triggers
- CPU usage < 35% AND Memory usage < 40%
- At least 300 seconds since last scaling
- Current replicas > minimum (1)

### Scaling Actions
- Scale up: +1 replica (max 5)
- Scale down: -1 replica (min 1)
- Logs show scaling decisions and metrics

## 6. Troubleshooting

### Autoscaler Not Scaling
```bash
# Check Prometheus connectivity
curl http://localhost:9090/api/v1/query?query=up

# Verify service name
docker service ls | grep service-a

# Check autoscaler logs for errors
```

### No Metrics Available
```bash
# Restart Prometheus
docker service update --force r4j-stack_prometheus

# Check service endpoints
curl http://localhost:8080/actuator/prometheus
```

### Manual Scaling Test
```bash
# Test manual scaling works
docker service scale r4j-stack_service-a=3
docker service scale r4j-stack_service-a=1
```