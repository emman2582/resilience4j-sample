# AWS Deployment Guide

Deploy the NodeJS client to AWS with different Service A deployment options.

## 🏗️ AWS Architecture Options

### Option 1: ECS with ALB
```
NodeJS Client → ALB → ECS Service A → ECS Service B
```

### Option 2: EKS with Ingress
```
NodeJS Client → ALB Ingress → EKS Service A → EKS Service B
```

### Option 3: Lambda with API Gateway
```
NodeJS Client → API Gateway → Lambda Service A → Lambda Service B
```

## 🚀 Quick AWS Setup

### 1. Deploy Services to AWS
```bash
# Option A: Using ECS
aws ecs create-cluster --cluster-name resilience4j-cluster

# Option B: Using EKS
eksctl create cluster --name resilience4j-cluster

# Option C: Using Lambda
sam deploy --template-file template.yaml
```

### 2. Configure NodeJS Client
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your AWS URLs
SERVICE_A_URL=https://your-alb-url.us-east-1.elb.amazonaws.com
REQUEST_TIMEOUT=15000
NODE_ENV=aws
```

### 3. Run Client
```bash
npm run start:aws
npm run test:aws
```

## ⚙️ Environment Configuration

### Local Development
```bash
SERVICE_A_URL=http://localhost:8080
REQUEST_TIMEOUT=10000
```

### AWS ALB/ELB
```bash
SERVICE_A_URL=https://your-alb-url.us-east-1.elb.amazonaws.com
REQUEST_TIMEOUT=15000
NODE_ENV=aws
```

### AWS API Gateway
```bash
SERVICE_A_URL=https://your-api-id.execute-api.us-east-1.amazonaws.com/prod
REQUEST_TIMEOUT=30000
NODE_ENV=aws
```

## 🔧 AWS-Specific Considerations

### Timeouts
- **Local**: 10s (fast local network)
- **AWS**: 15-30s (network latency + cold starts)

### Connection Limits
- **Local**: 10 concurrent connections
- **AWS**: 3-5 concurrent (avoid overwhelming services)

### Load Testing
- Use lower connection counts for AWS
- Longer test durations for meaningful results
- Consider AWS Lambda cold start times

## 🛠️ Troubleshooting

### Connection Issues
```bash
# Test connectivity
curl https://your-alb-url.us-east-1.elb.amazonaws.com/actuator/health

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Verify ALB target health
aws elbv2 describe-target-health --target-group-arn arn:aws:...
```

### Performance Issues
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB

# Monitor ECS service metrics
aws ecs describe-services --cluster resilience4j-cluster
```