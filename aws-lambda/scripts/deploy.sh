#!/bin/bash

# AWS Lambda Deployment Script
# Deploys all Lambda functions and infrastructure

set -e

REGION=${AWS_REGION:-us-east-1}
STACK_NAME=${STACK_NAME:-resilience4j-lambda}
S3_BUCKET=${S3_BUCKET:-resilience4j-lambda-deployments-$(date +%s)}

echo "🚀 Deploying AWS Lambda Resilience4j Stack..."
echo "Region: $REGION"
echo "Stack: $STACK_NAME"

# Create S3 bucket for deployments if it doesn't exist
if ! aws s3 ls "s3://$S3_BUCKET" 2>/dev/null; then
    echo "📦 Creating S3 bucket: $S3_BUCKET"
    aws s3 mb "s3://$S3_BUCKET" --region $REGION
fi

# Package Service A
echo "📦 Packaging Service A..."
cd functions/service-a
npm install --production
zip -r ../../service-a.zip . -x "*.git*" "node_modules/.cache/*" "*.test.js"
cd ../..

# Package Service B
echo "📦 Packaging Service B..."
cd functions/service-b
npm install --production
zip -r ../../service-b.zip . -x "*.git*" "node_modules/.cache/*" "*.test.js"
cd ../..

# Upload packages to S3
echo "⬆️ Uploading packages to S3..."
aws s3 cp service-a.zip "s3://$S3_BUCKET/service-a.zip"
aws s3 cp service-b.zip "s3://$S3_BUCKET/service-b.zip"

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file infrastructure/cloudformation/template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        S3Bucket=$S3_BUCKET \
        ServiceAZipKey=service-a.zip \
        ServiceBZipKey=service-b.zip \
    --capabilities CAPABILITY_IAM \
    --region $REGION

# Get API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

echo "✅ Deployment completed!"
echo "🌐 API Gateway URL: $API_URL"
echo "📊 Test endpoints:"
echo "  Health: $API_URL/health"
echo "  Service A: $API_URL/api/a/ok"
echo "  Service B: $API_URL/ok"

# Clean up local zip files
rm -f service-a.zip service-b.zip

echo "🧪 Run performance tests:"
echo "  cd performance-tests/artillery && npm run test:load"
echo "  cd performance-tests/locust && locust -f load_test.py --host=$API_URL"