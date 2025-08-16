#!/bin/bash

# Automated Lambda Performance Testing with Cleanup
# Deploys Lambda functions, runs tests, collects results, and cleans up

set -e

REGION=${AWS_REGION:-us-east-1}
STACK_NAME="resilience4j-lambda-test-$(date +%s)"
TEST_DURATION=${TEST_DURATION:-300}
RESULTS_DIR="results/$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting automated Lambda performance testing..."
echo "Stack: $STACK_NAME"
echo "Duration: ${TEST_DURATION}s"
echo "Results: $RESULTS_DIR"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Deploy Lambda functions
echo "📦 Deploying Lambda functions..."
export STACK_NAME
../scripts/deploy-containers.sh

# Get API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

echo "🌐 API Gateway URL: $API_URL"

# Wait for functions to warm up
echo "🔥 Warming up Lambda functions..."
for endpoint in "/health" "/api/a/ok" "/ok"; do
    curl -s "$API_URL$endpoint" > /dev/null || true
done
sleep 30

# Run Artillery tests
echo "🧪 Running Artillery performance tests..."
cd artillery
npm install --silent
sed "s|https://your-api-gateway-url.execute-api.region.amazonaws.com/prod|$API_URL|g" load-test.yml > load-test-configured.yml
artillery run load-test-configured.yml --output "../$RESULTS_DIR/artillery-results.json"
artillery report "../$RESULTS_DIR/artillery-results.json" --output "../$RESULTS_DIR/artillery-report.html"
cd ..

# Run Locust tests
echo "🐛 Running Locust performance tests..."
cd locust
pip install -r requirements.txt --quiet
locust -f load_test.py \
    --host="$API_URL" \
    --headless \
    --users=50 \
    --spawn-rate=5 \
    --run-time=${TEST_DURATION}s \
    --html="../$RESULTS_DIR/locust-report.html" \
    --csv="../$RESULTS_DIR/locust-results"
cd ..

# Collect CloudWatch metrics
echo "📊 Collecting CloudWatch metrics..."
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Duration \
    --dimensions Name=FunctionName,Value=service-a \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Average,Maximum,Minimum \
    --region $REGION > "$RESULTS_DIR/service-a-duration.json"

aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=service-a \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Sum \
    --region $REGION > "$RESULTS_DIR/service-a-invocations.json"

# Generate summary report
echo "📋 Generating summary report..."
cat > "$RESULTS_DIR/test-summary.md" << EOF
# Lambda Performance Test Results

**Test Configuration:**
- Stack Name: $STACK_NAME
- API Gateway URL: $API_URL
- Test Duration: ${TEST_DURATION}s
- Test Date: $(date)

**Files Generated:**
- Artillery Report: artillery-report.html
- Locust Report: locust-report.html
- CloudWatch Metrics: service-a-*.json

**Quick Results:**
$(tail -5 "$RESULTS_DIR/locust-results_stats.csv" 2>/dev/null || echo "Locust results not available")

**Next Steps:**
1. Open artillery-report.html in browser
2. Open locust-report.html in browser
3. Analyze CloudWatch metrics JSON files
EOF

# Cleanup Lambda functions
echo "🧹 Cleaning up Lambda functions..."
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
echo "⏳ Stack deletion initiated (will complete in background)"

# Cleanup ECR repositories
echo "🗑️ Cleaning up ECR repositories..."
../scripts/cleanup-containers.sh

echo "✅ Automated testing completed!"
echo "📊 Results available in: $RESULTS_DIR"
echo "📋 Summary: $RESULTS_DIR/test-summary.md"
echo "🌐 View reports:"
echo "  - Artillery: file://$PWD/$RESULTS_DIR/artillery-report.html"
echo "  - Locust: file://$PWD/$RESULTS_DIR/locust-report.html"