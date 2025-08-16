#!/bin/bash

# Cleanup Lambda containers and ECR repositories

set -e

REGION=${AWS_REGION:-us-east-1}

echo "🧹 Cleaning up Lambda containers..."

# Stop local containers
echo "🛑 Stopping local containers..."
docker-compose down || true

# Remove local images
echo "🗑️ Removing local images..."
docker rmi lambda-service-a:latest || true
docker rmi lambda-service-b:latest || true

# Delete ECR repositories
echo "🗑️ Deleting ECR repositories..."
for service in service-a service-b; do
    aws ecr delete-repository \
        --repository-name "lambda-$service" \
        --force \
        --region $REGION || true
done

# Delete Lambda functions
echo "🗑️ Deleting Lambda functions..."
aws lambda delete-function --function-name service-a --region $REGION || true
aws lambda delete-function --function-name service-b --region $REGION || true

echo "✅ Container cleanup completed!"