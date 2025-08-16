#!/bin/bash

# Deploy Lambda functions as containers to ECR and update Lambda

set -e

REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ Failed to get AWS account ID. Check AWS credentials."
    exit 1
fi
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "🐳 Deploying Lambda containers..."
echo "Region: $REGION"
echo "ECR Registry: $ECR_REGISTRY"

# Build Spring Boot JARs first
echo "🏧 Building Spring Boot applications..."
cd ../../
gradle clean build
cd aws-lambda

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Create ECR repositories if they don't exist
for service in service-a service-b; do
    if ! aws ecr describe-repositories --repository-names "lambda-$service" --region $REGION >/dev/null 2>&1; then
        echo "📦 Creating ECR repository: lambda-$service"
        aws ecr create-repository --repository-name "lambda-$service" --region $REGION
    fi
done

# Build and push Service A
echo "🔨 Building Service A container..."
cd ../service-a
docker build -f Dockerfile.lambda -t lambda-service-a .
docker tag lambda-service-a:latest $ECR_REGISTRY/lambda-service-a:latest
docker push $ECR_REGISTRY/lambda-service-a:latest
cd ../aws-lambda

# Build and push Service B
echo "🔨 Building Service B container..."
cd ../service-b
docker build -f Dockerfile.lambda -t lambda-service-b .
docker tag lambda-service-b:latest $ECR_REGISTRY/lambda-service-b:latest
docker push $ECR_REGISTRY/lambda-service-b:latest
cd ../aws-lambda

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
STACK_NAME=${STACK_NAME:-resilience4j-lambda}
aws cloudformation deploy \
    --template-file ../cloudformation-lambda/lambda-stack.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        ServiceAImageUri=$ECR_REGISTRY/lambda-service-a:latest \
        ServiceBImageUri=$ECR_REGISTRY/lambda-service-b:latest \
    --capabilities CAPABILITY_IAM \
    --region $REGION

# Get API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

if [ -z "$API_URL" ] || [ "$API_URL" = "None" ]; then
    echo "❌ Failed to get API Gateway URL from CloudFormation stack"
    exit 1
fi

echo "✅ Container deployment completed!"
echo "🌐 API Gateway URL: $API_URL"
echo "📊 Test endpoints:"
echo "  Health: $API_URL/health"
echo "  Service A: $API_URL/api/a/ok"
echo "  Service B: $API_URL/service-b/ok"