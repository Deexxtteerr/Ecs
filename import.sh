#!/bin/bash

echo "Starting Terraform import process..."

# Initialize Terraform
echo "1. Initializing Terraform..."
terraform init

# Import ECR Repository (us-east-1)
echo "2. Importing ECR repository..."
terraform import aws_ecr_repository.demo_app_repo demo-app-repo

# Import ECS Cluster (us-west-2)
echo "3. Importing ECS cluster..."
terraform import aws_ecs_cluster.demo_ecs_cluster demo-ecs-cluster

# Import IAM Role
echo "4. Importing IAM execution role..."
terraform import aws_iam_role.ecs_task_execution_role ecsTaskExecutionRole

# Import IAM Role Policy Attachment
echo "5. Importing IAM role policy attachment..."
terraform import aws_iam_role_policy_attachment.ecs_task_execution_role_policy ecsTaskExecutionRole/arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Import CloudWatch Log Group
echo "6. Importing CloudWatch log group..."
terraform import aws_cloudwatch_log_group.demo_ecs_example /ecs/demo-ecs-example

# Import ECS Task Definition
echo "7. Importing ECS task definition..."
terraform import aws_ecs_task_definition.demo_ecs_example demo-ecs-example

echo "Import process completed!"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to see if configuration matches existing resources"
echo "2. Make any necessary adjustments to main.tf"
echo "3. Run 'terraform apply' to confirm everything is in sync"
