#!/bin/bash

# ECS with Load Balancer and Auto Scaling Deployment Script
# Using Terraform CLI as requested by mentor

set -e

REGION="us-west-1"
ACCOUNT_ID="207567797053"
REPOSITORY_NAME="demo-app-repo"
IMAGE_TAG="latest"

echo "🚀 Starting ECS deployment with Load Balancer and Auto Scaling..."
echo "📋 This will create 32 AWS resources using Terraform CLI"

# Step 1: Deploy Infrastructure in phases
echo ""
echo "📦 Phase 1: Deploying Networking Infrastructure..."
terraform apply -target=aws_vpc.ecs_vpc -auto-approve
terraform apply -target=aws_internet_gateway.ecs_igw -auto-approve
terraform apply -target=aws_subnet.public -auto-approve
terraform apply -target=aws_subnet.private -auto-approve
terraform apply -target=aws_eip.nat -auto-approve
terraform apply -target=aws_nat_gateway.ecs_nat -auto-approve

echo "✅ Networking infrastructure deployed!"

echo ""
echo "🛣️  Phase 2: Deploying Routing..."
terraform apply -target=aws_route_table.public -auto-approve
terraform apply -target=aws_route_table.private -auto-approve
terraform apply -target=aws_route_table_association.public -auto-approve
terraform apply -target=aws_route_table_association.private -auto-approve

echo "✅ Routing configured!"

echo ""
echo "🔒 Phase 3: Deploying Security Groups..."
terraform apply -target=aws_security_group.alb -auto-approve
terraform apply -target=aws_security_group.ecs_tasks -auto-approve

echo "✅ Security groups created!"

echo ""
echo "🏗️  Phase 4: Deploying Core ECS Resources..."
terraform apply -target=aws_ecr_repository.demo_app_repo -auto-approve
terraform apply -target=aws_ecs_cluster.demo_ecs_cluster -auto-approve
terraform apply -target=aws_iam_role.ecs_task_execution_role -auto-approve
terraform apply -target=aws_iam_role_policy_attachment.ecs_task_execution_role_policy -auto-approve
terraform apply -target=aws_cloudwatch_log_group.demo_ecs_example -auto-approve
terraform apply -target=aws_ecs_task_definition.demo_ecs_example -auto-approve

echo "✅ Core ECS resources deployed!"

echo ""
echo "⚖️  Phase 5: Deploying Load Balancer..."
terraform apply -target=aws_lb.ecs_alb -auto-approve
terraform apply -target=aws_lb_target_group.ecs_tg -auto-approve
terraform apply -target=aws_lb_listener.ecs_listener -auto-approve

echo "✅ Load Balancer deployed!"

echo ""
echo "🔄 Phase 6: Deploying ECS Service and Auto Scaling..."
terraform apply -target=aws_ecs_service.ecs_service -auto-approve
terraform apply -target=aws_appautoscaling_target.ecs_target -auto-approve
terraform apply -target=aws_appautoscaling_policy.ecs_policy_cpu -auto-approve
terraform apply -target=aws_appautoscaling_policy.ecs_policy_memory -auto-approve

echo "✅ ECS Service and Auto Scaling deployed!"

echo ""
echo "🐳 Phase 7: Building and Pushing Docker Image..."

# Get ECR login token
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build Docker image
echo "🏗️  Building Docker image..."
docker build -t $REPOSITORY_NAME:$IMAGE_TAG .

# Tag image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

# Push image to ECR
echo "📤 Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo ""
echo "📊 Infrastructure Summary:"
echo "   ✅ VPC with public/private subnets across 2 AZs"
echo "   ✅ Application Load Balancer (ALB)"
echo "   ✅ ECS Service with 2 tasks (desired count)"
echo "   ✅ Auto Scaling (1-10 tasks based on CPU/Memory)"
echo "   ✅ NAT Gateways for private subnet internet access"
echo "   ✅ Security Groups with proper access controls"
echo ""
echo "🌐 Access your application:"
ALB_DNS=$(terraform output -raw load_balancer_dns)
echo "   Load Balancer URL: http://$ALB_DNS"
echo ""
echo "🔧 Useful CLI commands:"
echo "   # Check ECS service status"
echo "   aws ecs describe-services --cluster demo-ecs-cluster --services demo-ecs-service --region $REGION"
echo ""
echo "   # Check running tasks"
echo "   aws ecs list-tasks --cluster demo-ecs-cluster --region $REGION"
echo ""
echo "   # Check auto scaling status"
echo "   aws application-autoscaling describe-scalable-targets --service-namespace ecs --region $REGION"
echo ""
echo "   # Check load balancer health"
echo "   aws elbv2 describe-target-health --target-group-arn \$(terraform output -raw load_balancer_dns | cut -d'.' -f1) --region $REGION"
echo ""
echo "💰 Cost Estimate: ~$100-150/month (2 NAT Gateways, ALB, ECS Fargate tasks)"
echo "🔄 Auto Scaling: CPU > 70% or Memory > 80% triggers scale-out"
echo "📈 Monitoring: Check CloudWatch for metrics and logs"
