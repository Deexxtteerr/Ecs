# ECS Flask Application with Terraform

This project demonstrates how to deploy a Flask web application on AWS ECS using Terraform for Infrastructure as Code (IaC).

## Project Overview

- **Application**: Simple Flask web app with two endpoints
- **Container**: Docker containerized application
- **Registry**: AWS ECR (Elastic Container Registry)
- **Orchestration**: AWS ECS (Elastic Container Service) with Fargate
- **Infrastructure**: Managed with Terraform
- **Import Strategy**: Existing AWS resources imported into Terraform state

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   AWS ECR       │    │   AWS ECS       │
│                 │    │                 │    │                 │
│ Docker Build    │───▶│ Image Storage   │───▶│ Container Run   │
│ & Push          │    │ (us-east-1)     │    │ (us-west-2)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                               ┌─────────────────┐
                                               │ CloudWatch Logs │
                                               │ Monitoring      │
                                               └─────────────────┘
```

## Files Structure

```
ECS/
├── app.py                 # Flask application
├── Dockerfile            # Container definition
├── requirements.txt      # Python dependencies
├── main.tf              # Terraform configuration
├── import.sh            # Terraform import script
├── terraform.tfstate    # Terraform state (managed)
├── .terraform.lock.hcl  # Terraform lock file
└── README.md           # This file
```

## Application Details

### Flask App (`app.py`)
- **Root endpoint** (`/`): Returns "Hello, Flask on Docker!"
- **Greeting endpoint** (`/greet/<name>`): Returns personalized greeting
- **Port**: 3000
- **Host**: 0.0.0.0 (accessible from container)

### Dependencies (`requirements.txt`)
- **Flask 2.3.3**: Web framework
- **Werkzeug 2.3.7**: WSGI utility library (compatible version)

### Docker Configuration (`Dockerfile`)
- **Base Image**: python:3.9
- **Working Directory**: /app
- **Exposed Port**: 3000
- **Command**: python app.py

## AWS Infrastructure

### Resources Created
1. **ECR Repository** (`demo-app-repo`) - us-east-1
2. **ECS Cluster** (`demo-ecs-cluster`) - us-west-2
3. **Task Definition** (`demo-ecs-example`) - Fargate, 1024 CPU, 3072 Memory
4. **IAM Role** (`ecsTaskExecutionRole`) - ECS task execution permissions
5. **CloudWatch Log Group** (`/ecs/demo-ecs-example`) - Application logs

### Multi-Region Setup
- **ECR**: us-east-1 (image storage)
- **ECS**: us-west-2 (container execution)

## Terraform Configuration

### Providers
```hcl
# Multi-region setup
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

### Key Resources
- `aws_ecr_repository.demo_app_repo`
- `aws_ecs_cluster.demo_ecs_cluster`
- `aws_ecs_task_definition.demo_ecs_example`
- `aws_iam_role.ecs_task_execution_role`
- `aws_cloudwatch_log_group.demo_ecs_example`

## Deployment Process

### 1. Manual Infrastructure Creation
```bash
# Created through AWS Console:
# - ECR repository
# - ECS cluster
# - Task definition
# - IAM roles
```

### 2. Terraform Import Process
```bash
# Initialize Terraform
terraform init

# Import existing resources
./import.sh

# Verify configuration matches
terraform plan
```

### 3. Application Deployment
```bash
# Build Docker image
docker build -t demo-app-repo .

# Tag for ECR
docker tag demo-app-repo:latest 207567797053.dkr.ecr.us-east-1.amazonaws.com/demo-app-repo:v2

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 207567797053.dkr.ecr.us-east-1.amazonaws.com

# Push to ECR
docker push 207567797053.dkr.ecr.us-east-1.amazonaws.com/demo-app-repo:v2

# Update task definition and run
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs run-task --cluster demo-ecs-cluster --task-definition demo-ecs-example:3
```

## Troubleshooting

### Common Issues Fixed

1. **Flask Version Compatibility**
   - **Problem**: ImportError with Werkzeug url_quote
   - **Solution**: Updated Flask to 2.3.3 and Werkzeug to 2.3.7

2. **ECR Immutable Tags**
   - **Problem**: Cannot overwrite 'latest' tag
   - **Solution**: Use versioned tags (v2, v3, etc.)

3. **Route Parameter Mismatch**
   - **Problem**: Route defined as `<n>` but function parameter as `name`
   - **Solution**: Changed route to `<name>`

### Monitoring
- **CloudWatch Logs**: `/ecs/demo-ecs-example`
- **ECS Console**: Task status and health
- **ECR Console**: Image versions and scan results

## Commands Reference

### Docker Commands
```bash
# Build image
docker build -t demo-app-repo .

# Run locally for testing
docker run -p 3000:3000 demo-app-repo

# Tag for ECR
docker tag demo-app-repo:latest <account-id>.dkr.ecr.<region>.amazonaws.com/demo-app-repo:v2
```

### AWS CLI Commands
```bash
# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# List ECS tasks
aws ecs list-tasks --cluster demo-ecs-cluster --region us-west-2

# View logs
aws logs get-log-events --log-group-name "/ecs/demo-ecs-example" --log-stream-name <stream-name> --region us-west-2
```

### Terraform Commands
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Import existing resource
terraform import <resource_type>.<resource_name> <resource_id>
```

## Learning Outcomes

This project demonstrates:
1. **Infrastructure as Code**: Managing AWS resources with Terraform
2. **Import Strategy**: Bringing existing resources under Terraform management
3. **Multi-region Architecture**: ECR in one region, ECS in another
4. **Container Orchestration**: Running containerized applications on ECS
5. **Troubleshooting**: Debugging container and dependency issues
6. **DevOps Practices**: Version control, documentation, and reproducible deployments

## Next Steps

1. **Add Load Balancer**: Expose application publicly
2. **Auto Scaling**: Configure ECS service with auto scaling
3. **CI/CD Pipeline**: Automate build and deployment
4. **Monitoring**: Add CloudWatch alarms and dashboards
5. **Security**: Implement least privilege IAM policies
6. **Environment Management**: Separate dev/staging/prod environments

## Author

Created as part of DevOps learning journey - demonstrating Terraform import capabilities and ECS deployment patterns.
