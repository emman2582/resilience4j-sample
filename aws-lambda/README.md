# AWS Lambda Container Implementation

Containerizes existing Spring Boot service-a and service-b applications to run in AWS Lambda with automated performance testing.

## 🔄 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │───▶│   Lambda        │───▶│   Spring Boot   │
│                 │    │   Adapter       │    │   Application   │
│                 │    │   (Node.js)     │    │   (Java JAR)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Code Reuse Strategy:**
- Uses existing `service-a/` and `service-b/` Spring Boot applications
- Lambda adapters convert API Gateway events to HTTP requests
- No duplicate code maintenance required

## 📁 Project Structure

```
resilience4j-sample/
├── service-a/                 # Spring Boot + Lambda adapter
│   ├── Dockerfile.lambda      # Lambda container
│   ├── lambda-adapter.js      # Event converter
│   └── package-lambda.json    # Node.js deps
├── service-b/                 # Spring Boot + Lambda adapter
│   ├── Dockerfile.lambda      # Lambda container
│   ├── lambda-adapter.js      # Event converter
│   └── package-lambda.json    # Node.js deps
├── cloudformation-lambda/     # Infrastructure templates
│   └── lambda-stack.yaml      # Complete Lambda stack
└── aws-lambda/               # Deployment & testing only
    ├── performance-tests/    # Load testing
    └── scripts/              # Deploy/cleanup scripts
```

## 🚀 Quick Start

### Prerequisites
```bash
# Install AWS CLI and configure credentials
aws configure

# Install Docker
docker --version

# Install Node.js 18+
node --version
```

### Automated Testing (Recommended)
```bash
# Deploy, test, and cleanup automatically
cd performance-tests
./test-and-destroy.sh

# Custom test duration (default: 300s)
TEST_DURATION=600 ./test-and-destroy.sh
```

### Manual Deployment
```bash
# Build and deploy containers
./scripts/deploy-containers.sh

# Cleanup when done
./scripts/cleanup-containers.sh
```

## 🧪 Automated Test Pipeline

1. **Build** - Compile Spring Boot JARs
2. **Deploy** - Build and deploy Lambda containers
3. **Warm-up** - Initialize functions to avoid cold starts
4. **Test** - Run Artillery and Locust performance tests
5. **Collect** - Gather CloudWatch metrics and test results
6. **Cleanup** - Remove all AWS resources

### Test Results Generated
- **Artillery Report** - HTML with detailed performance metrics
- **Locust Report** - HTML with performance graphs
- **CloudWatch Metrics** - Lambda duration, invocations, errors
- **Test Summary** - Markdown summary with key findings

## 🔧 Configuration

### Environment Variables
```bash
TEST_DURATION=300        # Test duration in seconds
STACK_NAME=custom-name   # Override stack name
AWS_REGION=us-west-2     # Target region
```

### Lambda Settings
- **Memory**: 1024MB (Service A), 512MB (Service B)
- **Timeout**: 30 seconds
- **Runtime**: Container with Java 21 + Node.js 18
- **Tracing**: X-Ray enabled

## 💰 Cost Optimization

### Automatic Cleanup
- Stack deletion after testing
- ECR repository cleanup
- CloudWatch log group removal
- No persistent resources left running

### Efficient Testing
- Temporary stack names with timestamps
- Minimal resource allocation during tests
- Quick deployment and teardown cycle

## 🛠️ Troubleshooting

### Lambda Container Issues
```bash
# Check ECR repository
aws ecr describe-repositories --repository-names lambda-service-a

# Test container locally
docker run -p 9000:8080 lambda-service-a:latest

# Check Lambda function configuration
aws lambda get-function --function-name service-a

# View Lambda container logs
aws logs filter-log-events --log-group-name /aws/lambda/service-a
```

### Build Issues
```bash
# Ensure Spring Boot JARs are built
gradle clean build

# Check Docker is running
docker ps

# Verify AWS credentials
aws sts get-caller-identity
```

## 📊 Benefits

### Code Reuse
- ✅ Single codebase for all deployment targets
- ✅ Consistent behavior across environments
- ✅ Reduced maintenance overhead

### Serverless Advantages
- ✅ Pay-per-request pricing
- ✅ Automatic scaling
- ✅ No infrastructure management
- ✅ Built-in monitoring and logging

### Testing Efficiency
- ✅ Automated deployment and cleanup
- ✅ Comprehensive performance metrics
- ✅ Cost-effective testing cycles
- ✅ Reproducible test environments

This approach provides serverless deployment benefits while maintaining code consistency with existing Spring Boot applications.