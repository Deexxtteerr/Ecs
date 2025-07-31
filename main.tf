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

# ECR Repository in us-west-1 (moved from us-east-1)
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
}

# ECS Cluster in us-west-1 (moved from us-west-2)
resource "aws_ecs_cluster" "demo_ecs_cluster" {
  provider = aws.west1
  name     = "demo-ecs-cluster"
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
}

# ECS Task Definition in us-west-1
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
      image     = "207567797053.dkr.ecr.us-west-1.amazonaws.com/demo-app-repo"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          name          = "example-3000-tcp"
          appProtocol   = "http"
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
        secretOptions = []
      }

      environment      = []
      environmentFiles = []
      mountPoints      = []
      volumesFrom      = []
      ulimits          = []
      systemControls   = []
    }
  ])

  tags = {}
}
