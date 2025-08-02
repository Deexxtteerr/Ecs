# ECS Flask Application with Terraform

This project demonstrates how to deploy a Flask web application on AWS ECS using Terraform for Infrastructure as Code (IaC). The project includes **TWO DEPLOYMENT OPTIONS** to understand the differences between Fargate and EC2 launch types.

## 🚀 **DEPLOYMENT OPTIONS**

### **Option 1: Fargate Deployment (Serverless)**
- **File**: `main-fargate.tf`
- **Launch Type**: AWS Fargate (Serverless)
- **Management**: AWS handles all infrastructure automatically
- **Resources**: 32 AWS resources with private subnets and NAT gateways

### **Option 2: EC2 Deployment (Manual Infrastructure Management)**
- **File**: `main.tf` (current active deployment)
- **Launch Type**: EC2 instances
- **Management**: YOU manually configure all infrastructure
- **Resources**: 28 AWS resources with full control over EC2 instances

## 🌐 **LIVE APPLICATION - EC2 DEPLOYMENT**

**🚀 Current EC2-based deployment:**
- **Main URL**: http://ecs-ec2-alb-343386134.us-west-1.elb.amazonaws.com
- **Greeting Endpoint**: http://ecs-ec2-alb-343386134.us-west-1.elb.amazonaws.com/greet/YourName
- **Status**: ✅ **LIVE** - Running on EC2 instances WITHOUT Fargate
- **Launch Type**: EC2 (Manual infrastructure management)

## 🔄 **Key Differences: Fargate vs EC2**

### **Fargate (Serverless)**
- ✅ AWS manages everything automatically
- ✅ No EC2 instance management
- ✅ Pay per task (CPU/Memory)
- ❌ Less control over infrastructure
- ❌ Higher cost per resource

### **EC2 (Manual Management)**
- ✅ Full control over infrastructure
- ✅ Lower cost for consistent workloads
- ✅ Can SSH into instances for debugging
- ❌ YOU manage scaling, patching, monitoring
- ❌ More complex setup and maintenance

## Project Overview - EC2 Deployment

- **Application**: Simple Flask web app with two endpoints
- **Container**: Docker containerized application
- **Registry**: AWS ECR (Elastic Container Registry)
- **Orchestration**: AWS ECS (Elastic Container Service) with **EC2 Launch Type**
- **Compute**: EC2 instances with ECS-optimized AMI (t3.micro)
- **Load Balancer**: Application Load Balancer (manually configured)
- **Auto Scaling**: EC2 Auto Scaling Group with CloudWatch alarms
- **Infrastructure**: Managed with Terraform (28 AWS resources)
- **Network**: Public subnets (simplified architecture)
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

## 🏗️ **EC2 Deployment Architecture (Current)**

```
Internet → Application Load Balancer → Target Group → EC2 Instances → ECS Tasks
              ↓                           ↓              ↓              ↓
        Security Groups              Health Checks   Auto Scaling   Dynamic Ports
              ↓                           ↓              ↓              ↓
        Public Subnets              CloudWatch      Launch Template  Container Apps
              ↓                      Monitoring           ↓              ↓
        Route Tables                     ↓         t3.micro instances  Flask App
              ↓                    Application Logs       ↓
        Internet Gateway                 ↓         ECS-optimized AMI
```

**EC2 Infrastructure YOU Manually Configured:**
- **VPC and Networking**: Custom VPC, public subnets, route tables, internet gateway
- **EC2 Auto Scaling**: Launch template, auto scaling group (1-4 instances)
- **Load Balancer**: ALB, target groups, listeners, health checks
- **Security**: Security groups for ALB and EC2 instances
- **Monitoring**: CloudWatch alarms for CPU-based scaling
- **ECS Integration**: Container instances, dynamic port mapping

## Complete Command List for EC2-based ECS Web App Deployment

### 1. Navigate to project directory:
```bash
cd /home/nilesh/ECS
```

### 2. Deploy EC2-based ECS infrastructure:
```bash
# This deploys EC2 instances, ALB, Auto Scaling - NO Fargate
terraform apply -auto-approve
```

### 3. Deploy application to EC2 instances:
```bash
# Alternative: Use the dedicated EC2 deployment script
./deploy-ec2.sh
```

### 4. Get your URLs (EC2 deployment):
```bash
# Get main URL
terraform output load_balancer_url

# Get DNS name only
terraform output -raw load_balancer_dns

# Get complete greet URL
echo "$(terraform output -raw load_balancer_url)/greet/YourName"
```

### 5. Test your EC2-based endpoints:
```bash
# Test main endpoint
curl $(terraform output -raw load_balancer_url)

# Test greet endpoint
curl "$(terraform output -raw load_balancer_url)/greet/YourName"
```

### 6. Monitor your EC2 infrastructure:
```bash
# Check EC2 instances in ECS cluster
aws ecs list-container-instances --cluster demo-ecs-cluster-ec2 --region us-west-1

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ecs-ec2-asg --region us-west-1

# Check ECS service on EC2
aws ecs describe-services --cluster demo-ecs-cluster-ec2 --services demo-ecs-service-ec2 --region us-west-1

# Check load balancer target health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw load_balancer_dns | cut -d'.' -f1) --region us-west-1
```

### 7. When done (to avoid charges):
```bash
terraform destroy -auto-approve
```

## 📊 **Resource Management: EC2 vs Fargate**

### **EC2 Launch Type (Current Deployment)**
**What YOU Manually Configure:**
- ✅ **EC2 Instances**: Launch template, instance types, AMI selection
- ✅ **Auto Scaling Group**: Min/max instances, scaling policies
- ✅ **Load Balancer**: ALB creation, target groups, listeners
- ✅ **Security Groups**: Network access rules for ALB and EC2
- ✅ **CloudWatch Alarms**: CPU/memory thresholds for scaling
- ✅ **VPC Networking**: Subnets, route tables, internet gateway
- ✅ **Dynamic Port Mapping**: ECS assigns random ports to containers
- ✅ **Instance Maintenance**: Patching, monitoring, troubleshooting

**Resource Count**: 28 AWS resources
**Cost Model**: Pay for EC2 instances (even when idle)
**Control Level**: Full control over infrastructure

### **Fargate Launch Type (Alternative)**
**What AWS Manages Automatically:**
- 🤖 **Serverless**: No EC2 instances to manage
- 🤖 **Auto Scaling**: AWS handles task scaling automatically
- 🤖 **Load Balancer**: Automatic target registration/deregistration
- 🤖 **Security**: AWS manages underlying infrastructure security
- 🤖 **Networking**: Automatic ENI creation and management
- 🤖 **Monitoring**: Built-in CloudWatch integration
- 🤖 **Maintenance**: AWS handles all patching and updates

**Resource Count**: 32 AWS resources (includes NAT gateways, private subnets)
**Cost Model**: Pay per task (CPU/memory usage)
**Control Level**: Limited control, AWS abstracts infrastructure

## Files Structure

```
ECS/
├── app.py                                    # Flask application
├── Dockerfile                               # Container definition
├── requirements.txt                         # Python dependencies
├── main.tf                                  # EC2-based ECS configuration (28 resources)
├── main-fargate.tf                          # Fargate-based ECS configuration (32 resources)
├── deploy.sh                                # Basic Fargate deployment script
├── deploy-ec2.sh                           # EC2-based deployment script
├── deploy_with_lb_autoscaling.sh           # Production Fargate deployment
├── manage_ecs.sh                           # CLI management and monitoring tools
├── import.sh                               # Terraform import script
├── LOAD_BALANCER_AUTOSCALING_IMPLEMENTATION.md  # Detailed implementation docs
├── main.tf.backup                          # Backup configurations
├── terraform.tfstate                       # Terraform state (managed)
├── .terraform.lock.hcl                     # Terraform lock file
└── README.md                               # This file
```

## 🚀 **Deployment Scripts**

### **EC2 Deployment (Current)**
```bash
./deploy-ec2.sh    # Deploys EC2-based ECS with manual infrastructure management
```

### **Fargate Deployment (Alternative)**
```bash
./deploy.sh                           # Basic Fargate deployment
./deploy_with_lb_autoscaling.sh      # Production Fargate with full features
```
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
