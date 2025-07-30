# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for us-west-2 (where ECS cluster is)
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Provider for us-east-1 (where ECR repo is)
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

# ECR Repository in us-east-1 (existing)
resource "aws_ecr_repository" "demo_app_repo" {
  provider             = aws.east
  name                 = "demo-app-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# ECS Cluster in us-west-2 (existing)
resource "aws_ecs_cluster" "demo_ecs_cluster" {
  provider = aws.west
  name     = "demo-ecs-cluster"
}

# IAM Role for ECS Task Execution (existing)
resource "aws_iam_role" "ecs_task_execution_role" {
  provider = aws.west
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
  provider   = aws.west
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Group (auto-created by ECS)
resource "aws_cloudwatch_log_group" "demo_ecs_example" {
  provider          = aws.west
  name              = "/ecs/demo-ecs-example"
  retention_in_days = 0  # Never expire (default)
}

# ECS Task Definition (existing)
resource "aws_ecs_task_definition" "demo_ecs_example" {
  provider                 = aws.west
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
      image     = "207567797053.dkr.ecr.us-east-1.amazonaws.com/demo-app-repo"
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
          "awslogs-region"        = "us-west-2"
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
