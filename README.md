# ECS Flask Application with Terraform

This project demonstrates how to deploy a Flask web application on AWS ECS using Terraform for Infrastructure as Code (IaC) with **Production-Ready Load Balancer and Auto Scaling**.

## 🌐 **LIVE APPLICATION**

**🚀 Access the live application here:**
- **Main URL**: http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com
- **Greeting Endpoint**: http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com/greet/YourName
- **Status**: ✅ **LIVE** - Running with Load Balancer and Auto Scaling

## Project Overview

- **Application**: Simple Flask web app with two endpoints
- **Container**: Docker containerized application
- **Registry**: AWS ECR (Elastic Container Registry)
- **Orchestration**: AWS ECS (Elastic Container Service) with Fargate
- **Load Balancer**: Application Load Balancer with health checks
- **Auto Scaling**: CPU and Memory-based scaling (1-10 tasks)
- **Infrastructure**: Managed with Terraform (32 AWS resources)
- **Architecture**: Production-ready multi-AZ deployment

## 🏗️ **Production Architecture**

```
Internet → Application Load Balancer → Target Group → ECS Service → Tasks (Private Subnets)
              ↓                           ↓              ↓
        Security Groups              Health Checks   Auto Scaling
              ↓                           ↓              ↓
        Public Subnets              CloudWatch      CPU/Memory Policies
              ↓                      Monitoring           ↓
        NAT Gateways                     ↓         Scale 1-10 tasks
              ↓                    Application Logs
        Private Subnets
```

**Key Features:**
- **Multi-AZ**: High availability across us-west-1a and us-west-1c
- **Security**: Private subnets, security groups, NAT gateways
- **Scalability**: Auto scaling based on CPU (70%) and Memory (80%)
- **Monitoring**: CloudWatch logs and metrics integration

## Complete Command List for ECS Web App Deployment

### 1. Navigate to project directory:
```bash
cd /home/nilesh/ECS
```

### 2. Deploy infrastructure:
```bash
terraform apply -auto-approve
```

### 3. Deploy application:
```bash
./deploy.sh
```

### 4. Get your URLs:
```bash
# Get main URL
terraform output load_balancer_url

# Get DNS name only
terraform output -raw load_balancer_dns

# Get complete greet URL
echo "$(terraform output -raw load_balancer_url)/greet/YourName"
```

### 5. Test your endpoints:
```bash
# Test main endpoint
curl $(terraform output -raw load_balancer_url)

# Test greet endpoint
curl "$(terraform output -raw load_balancer_url)/greet/YourName"
```

### 6. When done (to avoid charges):
```bash
terraform destroy -auto-approve
```

## Files Structure

```
ECS/
├── app.py                                    # Flask application
├── Dockerfile                               # Container definition
├── requirements.txt                         # Python dependencies
├── main.tf                                  # Complete Terraform configuration (32 resources)
├── deploy.sh                                # Basic deployment script
├── deploy_with_lb_autoscaling.sh           # Production deployment with LB & Auto Scaling
├── manage_ecs.sh                           # CLI management and monitoring tools
├── import.sh                               # Terraform import script
├── LOAD_BALANCER_AUTOSCALING_IMPLEMENTATION.md  # Detailed implementation docs
├── main.tf.backup                          # Backup of original configuration
├── terraform.tfstate                       # Terraform state (managed)
├── .terraform.lock.hcl                     # Terraform lock file
└── README.md                               # This file
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

## 🚀 **Deployment Options**

### **Option 1: Production Deployment (Recommended)**
```bash
# Deploy with Load Balancer and Auto Scaling (32 resources)
./deploy_with_lb_autoscaling.sh
```
**Features:**
- ✅ Application Load Balancer with health checks
- ✅ Auto Scaling (CPU 70%, Memory 80%)
- ✅ Multi-AZ deployment (High Availability)
- ✅ VPC with public/private subnets
- ✅ Security groups and NAT gateways
- ✅ Production-ready architecture

### **Option 2: Basic Deployment**
```bash
# Simple ECS deployment (development/testing)
./deploy.sh
```
**Features:**
- ✅ Basic ECS cluster and tasks
- ✅ ECR integration
- ✅ CloudWatch logging
- ❌ No load balancer
- ❌ No auto scaling

## 📊 **Management & Monitoring**

```bash
# Check overall status
./manage_ecs.sh status

# View running tasks
./manage_ecs.sh tasks

# Check auto scaling configuration
./manage_ecs.sh scale

# Monitor load balancer health
./manage_ecs.sh health

# View application logs
./manage_ecs.sh logs

# Show all endpoints
./manage_ecs.sh endpoints
```

## AWS Infrastructure

### 🏗️ **Production Resources (32 Total)**

**Networking (15 resources):**
1. **VPC** (`ecs-vpc`) - Custom VPC with DNS support
2. **Public Subnets** (2) - For Load Balancer across AZs
3. **Private Subnets** (2) - For ECS tasks (secure)
4. **Internet Gateway** - Public internet access
5. **NAT Gateways** (2) - Private subnet internet access
6. **Route Tables** (3) - Traffic routing
7. **Route Associations** (4) - Subnet routing
8. **Elastic IPs** (2) - For NAT gateways

**Load Balancer (3 resources):**
1. **Application Load Balancer** (`ecs-alb`) - Internet-facing
2. **Target Group** (`ecs-target-group`) - Health checks on port 3000
3. **Listener** - HTTP traffic forwarding

**ECS & Compute (6 resources):**
1. **ECR Repository** (`demo-app-repo`) - us-west-1
2. **ECS Cluster** (`demo-ecs-cluster`) - us-west-1
3. **Task Definition** (`demo-ecs-example`) - Fargate, 1024 CPU, 3072 Memory
4. **ECS Service** (`demo-ecs-service`) - 2 tasks, integrated with ALB
5. **IAM Role** (`ecsTaskExecutionRole`) - ECS task execution permissions
6. **CloudWatch Log Group** (`/ecs/demo-ecs-example`) - Application logs

**Auto Scaling (3 resources):**
1. **Scaling Target** - Min: 1, Max: 10 tasks
2. **CPU Scaling Policy** - Scale at 70% CPU utilization
3. **Memory Scaling Policy** - Scale at 80% memory utilization

**Security (2 resources):**
1. **ALB Security Group** - HTTP/HTTPS from internet
2. **ECS Security Group** - Port 3000 from ALB only

**Additional (3 resources):**
- IAM policy attachments and data sources

### 🌍 **Unified Region Setup**
- **All Resources**: us-west-1 (optimized for performance and cost)
- **Multi-AZ**: High availability across us-west-1a and us-west-1c

## Terraform Configuration

### Provider
```hcl
# Unified region setup
provider "aws" {
  alias  = "west1"
  region = "us-west-1"
}
```

### Key Resources
- `aws_vpc.ecs_vpc` - Custom VPC with DNS support
- `aws_lb.ecs_alb` - Application Load Balancer
- `aws_ecs_service.ecs_service` - ECS Service with ALB integration
- `aws_appautoscaling_target.ecs_target` - Auto scaling configuration
- `aws_security_group.alb` & `aws_security_group.ecs_tasks` - Security
- `aws_nat_gateway.ecs_nat` - Private subnet internet access

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
1. **Infrastructure as Code**: Complete AWS infrastructure with Terraform (32 resources)
2. **Production Architecture**: Load Balancer, Auto Scaling, Multi-AZ deployment
3. **Security Best Practices**: Private subnets, security groups, NAT gateways
4. **Container Orchestration**: ECS Service with Fargate and load balancer integration
5. **Auto Scaling**: CPU and memory-based scaling policies
6. **DevOps Practices**: CLI-only deployment, monitoring, and documentation
7. **High Availability**: Multi-AZ deployment with health checks

## 🌐 **Live Application Access**

**🚀 Your application is live and accessible:**

- **Main Application**: http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com
- **Personalized Greeting**: http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com/greet/YourName
- **Health Check**: Automatic via Load Balancer
- **Status**: ✅ **ACTIVE** with 2 healthy tasks

**Test Commands:**
```bash
# Test main endpoint
curl http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com

# Test with your name
curl http://ecs-alb-1484419533.us-west-1.elb.amazonaws.com/greet/Nilesh
```

## Next Steps (Completed ✅)

1. ✅ **Load Balancer**: Application Load Balancer implemented
2. ✅ **Auto Scaling**: CPU/Memory-based scaling configured
3. ✅ **Monitoring**: CloudWatch logs and metrics integrated
4. ✅ **Security**: Private subnets and security groups implemented
5. ✅ **High Availability**: Multi-AZ deployment across 2 zones

**Future Enhancements:**
- CI/CD Pipeline integration
- HTTPS/SSL certificate
- Custom domain with Route 53
- Blue/Green deployment strategy

## Author

Created as part of DevOps learning journey - demonstrating advanced ECS deployment with Load Balancer, Auto Scaling, and production-ready architecture using Terraform CLI.
