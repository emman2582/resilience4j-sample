#!/bin/bash

# AWS Lambda Cleanup Script
# Removes all Lambda functions, API Gateway, and associated resources

set -e

REGION=${AWS_REGION:-us-east-1}
STACK_NAME=${STACK_NAME:-resilience4j-lambda}

echo "🧹 Cleaning up AWS Lambda Resilience4j Stack..."
echo "Region: $REGION"
echo "Stack: $STACK_NAME"

# Delete CloudFormation stack
echo "🗑️ Deleting CloudFormation stack..."
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

# Wait for stack deletion
echo "⏳ Waiting for stack deletion..."
aws cloudformation wait stack-delete-complete \
    --stack-name $STACK_NAME \
    --region $REGION

# Clean up S3 bucket if specified
if [ ! -z "$S3_BUCKET" ]; then
    echo "🗑️ Cleaning up S3 bucket: $S3_BUCKET"
    aws s3 rm "s3://$S3_BUCKET" --recursive
    aws s3 rb "s3://$S3_BUCKET"
fi

# Clean up CloudWatch log groups
echo "🗑️ Cleaning up CloudWatch log groups..."
aws logs delete-log-group --log-group-name "/aws/lambda/service-a" --region $REGION || true
aws logs delete-log-group --log-group-name "/aws/lambda/service-b" --region $REGION || true
aws logs delete-log-group --log-group-name "/aws/apigateway/$STACK_NAME" --region $REGION || true

# Clean up DynamoDB table
echo "🗑️ Cleaning up DynamoDB table..."
aws dynamodb delete-table --table-name "resilience4j-circuit-breaker-state" --region $REGION || true

echo "✅ Cleanup completed!"
echo "💰 Check AWS billing to ensure all resources are removed"