# EC2-based ECS Configuration - Manual ALB and Auto Scaling Management
# This shows the difference from Fargate where YOU handle everything

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "west1"
  region = "us-west-1"
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  provider = aws.west1
  state    = "available"
}

# Get the latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  provider    = aws.west1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# VPC for ECS resources
resource "aws_vpc" "ecs_vpc" {
  provider             = aws.west1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-ec2-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs_igw" {
  provider = aws.west1
  vpc_id   = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-ec2-igw"
  }
}

# Public Subnets for ALB and EC2 instances
resource "aws_subnet" "public" {
  provider                = aws.west1
  count                   = 2
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-ec2-public-subnet-${count.index + 1}"
    Type = "Public"
  }
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
    Name = "ecs-ec2-public-rt"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  provider       = aws.west1
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  provider    = aws.west1
  name        = "ecs-ec2-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "ecs-ec2-alb-sg"
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_instances" {
  provider    = aws.west1
  name        = "ecs-ec2-instances-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = aws_vpc.ecs_vpc.id

  # Allow HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow dynamic port range from ALB (for ECS tasks)
  ingress {
    description     = "Dynamic ports from ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow SSH (optional for debugging)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "ecs-ec2-instances-sg"
  }
}

# ECR Repository
resource "aws_ecr_repository" "demo_app_repo" {
  provider             = aws.west1
  name                 = "demo-app-repo-ec2"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "demo-app-repo-ec2"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "demo_ecs_cluster" {
  provider = aws.west1
  name     = "demo-ecs-cluster-ec2"

  tags = {
    Name = "demo-ecs-cluster-ec2"
  }
}

# IAM Role for ECS EC2 instances
resource "aws_iam_role" "ecs_instance_role" {
  provider = aws.west1
  name     = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecsInstanceRole"
  }
}

# Attach ECS instance policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  provider   = aws.west1
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# IAM instance profile for EC2 instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  provider = aws.west1
  name     = "ecsInstanceProfile"
  role     = aws_iam_role.ecs_instance_role.name
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  provider = aws.west1
  name     = "ecsTaskExecutionRole-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecsTaskExecutionRole-ec2"
  }
}

# Attach the ECS task execution role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  provider   = aws.west1
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Launch Template for EC2 instances
resource "aws_launch_template" "ecs_launch_template" {
  provider      = aws.west1
  name          = "ecs-ec2-launch-template"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2_instances.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.demo_ecs_cluster.name} >> /etc/ecs/ecs.config
    echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-ec2-instance"
    }
  }

  tags = {
    Name = "ecs-ec2-launch-template"
  }
}

# Auto Scaling Group for EC2 instances
resource "aws_autoscaling_group" "ecs_asg" {
  provider            = aws.west1
  name                = "ecs-ec2-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.ecs_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-ec2-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }
}

# Application Load Balancer (YOU manage this, not AWS)
resource "aws_lb" "ecs_alb" {
  provider           = aws.west1
  name               = "ecs-ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "ecs-ec2-alb"
  }
}

# Target Group for ECS Service (YOU configure this)
resource "aws_lb_target_group" "ecs_tg" {
  provider    = aws.west1
  name        = "ecs-ec2-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "instance"

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
    Name = "ecs-ec2-target-group"
  }
}

# Load Balancer Listener (YOU configure this)
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

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "demo_ecs_example" {
  provider          = aws.west1
  name              = "/ecs/demo-ecs-example-ec2"
  retention_in_days = 0

  tags = {
    Name = "demo-ecs-example-ec2-logs"
  }
}

# ECS Task Definition (for EC2 launch type)
resource "aws_ecs_task_definition" "demo_ecs_example" {
  provider             = aws.west1
  family               = "demo-ecs-example-ec2"
  network_mode         = "bridge"  # Different from Fargate
  requires_compatibilities = ["EC2"]  # EC2 instead of FARGATE
  execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "example"
      image     = "207567797053.dkr.ecr.us-west-1.amazonaws.com/demo-app-repo-ec2:latest"
      essential = true
      memory    = 512  # Hard limit for EC2

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 0  # Dynamic port mapping
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/demo-ecs-example-ec2"
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment      = []
      environmentFiles = []
      mountPoints      = []
      volumesFrom      = []
    }
  ])

  tags = {
    Name = "demo-ecs-example-ec2"
  }
}

# ECS Service (YOU manage scaling, not AWS)
resource "aws_ecs_service" "ecs_service" {
  provider        = aws.west1
  name            = "demo-ecs-service-ec2"
  cluster         = aws_ecs_cluster.demo_ecs_cluster.id
  task_definition = aws_ecs_task_definition.demo_ecs_example.arn
  desired_count   = 2
  launch_type     = "EC2"  # EC2 instead of FARGATE

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "example"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.ecs_listener]

  tags = {
    Name = "demo-ecs-service-ec2"
  }
}

# Auto Scaling Policies for EC2 instances (YOU configure these)
resource "aws_autoscaling_policy" "scale_up" {
  provider           = aws.west1
  name               = "ecs-ec2-scale-up"
  scaling_adjustment = 1
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  provider           = aws.west1
  name               = "ecs-ec2-scale-down"
  scaling_adjustment = -1
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

# CloudWatch Alarms for Auto Scaling (YOU set these up)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  provider            = aws.west1
  alarm_name          = "ecs-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  provider            = aws.west1
  alarm_name          = "ecs-ec2-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
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

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.demo_ecs_cluster.name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.name
}
