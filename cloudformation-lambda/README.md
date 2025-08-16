# CloudFormation Lambda Infrastructure

AWS CloudFormation template for deploying Resilience4j Spring Boot applications as Lambda container functions with complete infrastructure.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │──▶│   Lambda        │───▶│   DynamoDB      │
│                 │    │   Functions     │    │   State Store   │
│                 │    │   (Containers)  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudWatch    │    │   X-Ray         │    │   ECR           │
│   Logs/Metrics  │    │   Tracing       │    │   Repositories  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Template Components

- **Lambda Functions** - Service A and Service B as container functions
- **API Gateway** - REST API with proxy integration
- **DynamoDB** - Circuit breaker state persistence
- **IAM Roles** - Execution permissions and policies
- **CloudWatch** - Logging and monitoring
- **X-Ray** - Distributed tracing

## 🚀 Quick Deployment

### Prerequisites
```bash
# AWS CLI configured
aws configure

# Docker images built and pushed to ECR
cd ../aws-lambda
./scripts/deploy-containers.sh
```

### Deploy Stack
```bash
# Get ECR image URIs
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-us-east-1}
SERVICE_A_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/lambda-service-a:latest"
SERVICE_B_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/lambda-service-b:latest"

# Deploy CloudFormation stack
aws cloudformation deploy \
  --template-file lambda-stack.yaml \
  --stack-name resilience4j-lambda \
  --parameter-overrides \
    ServiceAImageUri=$SERVICE_A_URI \
    ServiceBImageUri=$SERVICE_B_URI \
  --capabilities CAPABILITY_IAM \
  --region $REGION
```

### Get API Gateway URL
```bash
aws cloudformation describe-stacks \
  --stack-name resilience4j-lambda \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text
```

## 🧪 Testing

### Basic Connectivity
```bash
API_URL=$(aws cloudformation describe-stacks \
  --stack-name resilience4j-lambda \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

# Test endpoints
curl $API_URL/health
curl $API_URL/api/a/ok
curl $API_URL/service-b/ok
```

### Resilience Patterns
```bash
# Circuit breaker
curl "$API_URL/api/a/flaky?failRate=60"

# Timeout
curl "$API_URL/api/a/slow?delayMs=2500"

# Bulkhead
curl $API_URL/api/a/bulkhead/x
curl $API_URL/api/a/bulkhead/y

# Rate limiter
curl $API_URL/api/a/limited
```

## ⚙️ Configuration

### Template Parameters

```yaml
Parameters:
  ServiceAImageUri:
    Type: String
    Description: ECR URI for Service A container image
    
  ServiceBImageUri:
    Type: String
    Description: ECR URI for Service B container image
```

### Lambda Function Settings

```yaml
ServiceAFunction:
  Type: AWS::Lambda::Function
  Properties:
    PackageType: Image
    Timeout: 30
    MemorySize: 1024
    Environment:
      Variables:
        SERVICE_B_URL: !Sub 'https://${ApiGateway}.execute-api.${AWS::Region}.amazonaws.com/prod/service-b'
        DYNAMODB_TABLE: !Ref CircuitBreakerTable
```

### API Gateway Configuration

```yaml
ApiGateway:
  Type: AWS::ApiGateway::RestApi
  Properties:
    Name: resilience4j-lambda-api
    Description: API Gateway for Resilience4j Lambda functions
```

## 📊 Monitoring

### CloudWatch Logs
```bash
# View Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/service

# Stream logs
aws logs tail /aws/lambda/service-a --follow
```

### CloudWatch Metrics
```bash
# Lambda metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=service-a \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

### X-Ray Tracing
```bash
# Get trace summaries
aws xray get-trace-summaries \
  --time-range-type TimeRangeByStartTime \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S)
```

## 🔧 Management

### Update Stack
```bash
# Update with new image URIs
aws cloudformation deploy \
  --template-file lambda-stack.yaml \
  --stack-name resilience4j-lambda \
  --parameter-overrides \
    ServiceAImageUri=$NEW_SERVICE_A_URI \
    ServiceBImageUri=$NEW_SERVICE_B_URI \
  --capabilities CAPABILITY_IAM
```

### Scale Configuration
```bash
# Update memory/timeout via parameter overrides
aws cloudformation deploy \
  --template-file lambda-stack.yaml \
  --stack-name resilience4j-lambda \
  --parameter-overrides \
    ServiceAMemorySize=2048 \
    ServiceATimeout=60 \
  --capabilities CAPABILITY_IAM
```

## 🛠️ Troubleshooting

### Stack Deployment Issues

**CREATE_FAILED - Invalid image URI:**
```bash
# Verify ECR repositories exist
aws ecr describe-repositories --repository-names lambda-service-a lambda-service-b

# Check image exists
aws ecr describe-images --repository-name lambda-service-a
```

**CREATE_FAILED - Insufficient permissions:**
```bash
# Check IAM permissions
aws iam get-user
aws sts get-caller-identity

# Required permissions:
# - cloudformation:*
# - lambda:*
# - apigateway:*
# - dynamodb:*
# - iam:CreateRole, iam:AttachRolePolicy
```

### Lambda Function Issues

**Function timeout:**
```bash
# Check function configuration
aws lambda get-function --function-name service-a

# View recent errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/service-a \
  --filter-pattern "ERROR"
```

**Cold start issues:**
```bash
# Warm up functions
curl $API_URL/health
curl $API_URL/service-b/health

# Check initialization time
aws logs filter-log-events \
  --log-group-name /aws/lambda/service-a \
  --filter-pattern "INIT_START"
```

### API Gateway Issues

**502 Bad Gateway:**
```bash
# Check Lambda function logs
aws logs tail /aws/lambda/service-a --since 10m

# Test Lambda directly
aws lambda invoke \
  --function-name service-a \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json
```

**403 Forbidden:**
```bash
# Check API Gateway permissions
aws lambda get-policy --function-name service-a

# Verify resource policy
aws apigateway get-rest-apis
```

### DynamoDB Issues

**Access denied:**
```bash
# Check IAM role permissions
aws iam get-role --role-name $(aws lambda get-function --function-name service-a --query 'Configuration.Role' --output text | cut -d'/' -f2)

# Test DynamoDB access
aws dynamodb describe-table --table-name resilience4j-circuit-breaker-state
```

### Container Issues

**ImagePullBackOff equivalent:**
```bash
# Check if image exists in ECR
aws ecr describe-images --repository-name lambda-service-a

# Verify image URI format
echo $SERVICE_A_URI
# Should be: 123456789.dkr.ecr.region.amazonaws.com/lambda-service-a:latest
```

**Container startup failures:**
```bash
# Check container logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/service-a \
  --filter-pattern "START RequestId"

# Test container locally
docker run -p 9000:8080 lambda-service-a:latest
```

### Performance Issues

**High latency:**
```bash
# Check memory allocation
aws lambda get-function-configuration --function-name service-a

# Monitor duration metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=service-a \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum,Minimum
```

**Throttling:**
```bash
# Check throttle metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=service-a \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 🧹 Cleanup

### Delete Stack
```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name resilience4j-lambda

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name resilience4j-lambda
```

### Clean ECR Images
```bash
# Delete ECR repositories
aws ecr delete-repository --repository-name lambda-service-a --force
aws ecr delete-repository --repository-name lambda-service-b --force
```

### Verify Cleanup
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name resilience4j-lambda

# Should return: Stack with id resilience4j-lambda does not exist
```

## 📋 Template Outputs

The CloudFormation template provides these outputs:

- **ApiGatewayUrl** - Base URL for API Gateway
- **ServiceAFunctionArn** - ARN of Service A Lambda function
- **ServiceBFunctionArn** - ARN of Service B Lambda function

## 🔐 Security Considerations

- **IAM Roles** - Least privilege access for Lambda functions
- **VPC** - Optional VPC configuration for network isolation
- **Encryption** - DynamoDB encryption at rest enabled
- **API Gateway** - Consider adding API keys or authorization
- **X-Ray** - Tracing enabled for observability

## 💰 Cost Optimization

- **Memory Sizing** - Right-size memory allocation (1024MB Service A, 512MB Service B)
- **Timeout** - Set appropriate timeouts (30s default)
- **Provisioned Concurrency** - Only if consistent low latency required
- **DynamoDB** - Pay-per-request billing mode for variable workloads

This CloudFormation template provides a complete serverless infrastructure for the Resilience4j sample application with proper monitoring, security, and cost optimization.