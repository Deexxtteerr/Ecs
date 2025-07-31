# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for us-west-1 (unified region for both ECS and ECR)
provider "aws" {
  alias  = "west1"
  region = "us-west-1"
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  provider = aws.west1
  state    = "available"
}

# VPC for ECS resources
resource "aws_vpc" "ecs_vpc" {
  provider             = aws.west1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs_igw" {
  provider = aws.west1
  vpc_id   = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-igw"
  }
}

# Public Subnets for Load Balancer
resource "aws_subnet" "public" {
  provider                = aws.west1
  count                   = 2
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# Private Subnets for ECS Tasks
resource "aws_subnet" "private" {
  provider          = aws.west1
  count             = 2
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ecs-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  provider = aws.west1
  count    = 2
  domain   = "vpc"

  tags = {
    Name = "ecs-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.ecs_igw]
}

# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "ecs_nat" {
  provider      = aws.west1
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "ecs-nat-gateway-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.ecs_igw]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  provider = aws.west1
  vpc_id   = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "ecs-public-rt"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  provider = aws.west1
  count    = 2
  vpc_id   = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat[count.index].id
  }

  tags = {
    Name = "ecs-private-rt-${count.index + 1}"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  provider       = aws.west1
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  provider       = aws.west1
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  provider    = aws.west1
  name        = "ecs-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-alb-sg"
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  provider    = aws.west1
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}

# ECR Repository in us-west-1
resource "aws_ecr_repository" "demo_app_repo" {
  provider             = aws.west1
  name                 = "demo-app-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "demo-app-repo"
  }
}

# ECS Cluster in us-west-1
resource "aws_ecs_cluster" "demo_ecs_cluster" {
  provider = aws.west1
  name     = "demo-ecs-cluster"

  tags = {
    Name = "demo-ecs-cluster"
  }
}

# IAM Role for ECS Task Execution in us-west-1
resource "aws_iam_role" "ecs_task_execution_role" {
  provider = aws.west1
  name     = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Name = "ecsTaskExecutionRole"
  }
}

# Attach the ECS task execution role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  provider   = aws.west1
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Group in us-west-1
resource "aws_cloudwatch_log_group" "demo_ecs_example" {
  provider          = aws.west1
  name              = "/ecs/demo-ecs-example"
  retention_in_days = 0  # Never expire (default)

  tags = {
    Name = "demo-ecs-example-logs"
  }
}

# ECS Task Definition in us-west-1 (Updated for Load Balancer)
resource "aws_ecs_task_definition" "demo_ecs_example" {
  provider                 = aws.west1
  family                   = "demo-ecs-example"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "example"
      image     = "207567797053.dkr.ecr.us-west-1.amazonaws.com/demo-app-repo:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
          name          = "example-3000-tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/demo-ecs-example"
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment      = []
      environmentFiles = []
      mountPoints      = []
      volumesFrom      = []
      ulimits          = []
      systemControls   = []
    }
  ])

  tags = {
    Name = "demo-ecs-example"
  }
}

# Application Load Balancer
resource "aws_lb" "ecs_alb" {
  provider           = aws.west1
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "ecs-alb"
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "ecs_tg" {
  provider    = aws.west1
  name        = "ecs-target-group"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "ecs-target-group"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "ecs_listener" {
  provider          = aws.west1
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# ECS Service
resource "aws_ecs_service" "ecs_service" {
  provider        = aws.west1
  name            = "demo-ecs-service"
  cluster         = aws_ecs_cluster.demo_ecs_cluster.id
  task_definition = aws_ecs_task_definition.demo_ecs_example.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "example"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.ecs_listener]

  tags = {
    Name = "demo-ecs-service"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  provider           = aws.west1
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.demo_ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU Based
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  provider           = aws.west1
  name               = "ecs-scale-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Policy - Memory Based
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  provider           = aws.west1
  name               = "ecs-scale-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# Outputs
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.ecs_alb.dns_name
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.ecs_alb.dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.ecs_vpc.id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.ecs_service.name
}
