#!/bin/bash

# Deployment script for ECS Flask app in us-west-1
set -e

REGION="us-west-1"
ACCOUNT_ID="207567797053"
REPOSITORY_NAME="demo-app-repo"
IMAGE_TAG="latest"

echo "🚀 Starting deployment to us-west-1..."

# Step 1: Apply Terraform configuration
echo "📋 Applying Terraform configuration..."
terraform apply -auto-approve

# Step 2: Get ECR login token
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 3: Build Docker image
echo "🏗️  Building Docker image..."
docker build -t $REPOSITORY_NAME:$IMAGE_TAG .

# Step 4: Tag image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

# Step 5: Push image to ECR
echo "📤 Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

echo "✅ Deployment completed successfully!"
echo "📍 All resources are now in us-west-1:"
echo "   - ECR Repository: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME"
echo "   - ECS Cluster: demo-ecs-cluster"
echo "   - CloudWatch Logs: /ecs/demo-ecs-example"

echo ""
echo "🔧 Next steps:"
echo "   1. Create an ECS service to run your task"
echo "   2. Set up load balancer and networking (VPC, subnets, security groups)"
echo "   3. Configure auto-scaling if needed"
