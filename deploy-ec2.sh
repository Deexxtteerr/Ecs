#!/bin/bash

# EC2-based ECS Deployment Script
# This shows the difference: YOU handle ALB, Auto Scaling, and EC2 instances manually

set -e

REGION="us-west-1"
ACCOUNT_ID="207567797053"
REPOSITORY_NAME="demo-app-repo-ec2"
IMAGE_TAG="latest"

echo "🚀 Starting EC2-based ECS deployment..."
echo "📋 YOU will manually configure:"
echo "   - EC2 instances for ECS cluster"
echo "   - Application Load Balancer"
echo "   - Auto Scaling Groups"
echo "   - Security Groups"
echo "   - CloudWatch Alarms"
echo ""

# Step 1: Initialize Terraform (if needed)
echo "📦 Initializing Terraform..."
terraform init

# Step 2: Apply EC2-based infrastructure
echo "🏗️  Deploying EC2-based ECS infrastructure..."
echo "   This will create:"
echo "   - VPC and subnets"
echo "   - EC2 instances with ECS agent"
echo "   - Auto Scaling Group (1-4 instances)"
echo "   - Application Load Balancer"
echo "   - Target Groups and Listeners"
echo "   - CloudWatch Alarms for scaling"
echo ""
terraform apply -auto-approve

# Step 3: Get ECR login token
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 4: Build Docker image
echo "🏗️  Building Docker image..."
docker build -t $REPOSITORY_NAME:$IMAGE_TAG .

# Step 5: Tag image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

# Step 6: Push image to ECR
echo "📤 Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

echo ""
echo "🎉 EC2-based ECS deployment completed!"
echo ""
echo "📊 What YOU manually configured (vs Fargate doing it automatically):"
echo "   ✅ EC2 instances with ECS-optimized AMI"
echo "   ✅ Auto Scaling Group (min: 1, max: 4, desired: 2)"
echo "   ✅ Application Load Balancer with target groups"
echo "   ✅ Security groups for ALB and EC2 instances"
echo "   ✅ CloudWatch alarms for CPU-based scaling"
echo "   ✅ IAM roles for EC2 instances and ECS tasks"
echo "   ✅ Launch template with user data for ECS agent"
echo ""
echo "🌐 Access your application:"
ALB_DNS=$(terraform output -raw load_balancer_dns)
echo "   Load Balancer URL: http://$ALB_DNS"
echo "   Greet Endpoint: http://$ALB_DNS/greet/YourName"
echo ""
echo "🔧 Key Differences from Fargate:"
echo "   - Fargate: AWS manages everything automatically"
echo "   - EC2: YOU configured all infrastructure components"
echo "   - EC2: You manage instance scaling, patching, monitoring"
echo "   - EC2: More control but more responsibility"
echo ""
echo "📈 Monitoring Commands:"
echo "   # Check EC2 instances in cluster"
echo "   aws ecs list-container-instances --cluster demo-ecs-cluster-ec2 --region $REGION"
echo ""
echo "   # Check Auto Scaling Group"
echo "   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ecs-ec2-asg --region $REGION"
echo ""
echo "   # Check ECS service"
echo "   aws ecs describe-services --cluster demo-ecs-cluster-ec2 --services demo-ecs-service-ec2 --region $REGION"
echo ""
echo "💰 Cost Comparison:"
echo "   - Fargate: Pay per task (CPU/Memory) - AWS manages infrastructure"
echo "   - EC2: Pay for EC2 instances (even if not fully utilized) - You manage everything"
