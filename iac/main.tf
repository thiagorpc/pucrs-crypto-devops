/*

Autor: Thiago Costa

✅ O que este Terraform faz:
  - Cria VPC, subnets públicas e IGW
  - Cria Security Group permitindo acesso HTTP
  - Cria ECR para armazenar imagens Docker
  - Cria ECS Cluster
  - Cria IAM Role para execução da Task ECS
  - Cria Application Load Balancer + Target Group + Listener
  - Cria ECS Fargate Service conectado ao ALB
  - Gera output com o DNS do ALB
  - Cria o S3 para o Frontend
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ID aleatório para garantir nome único do bucket
resource "random_id" "unique_id" {
  byte_length = 8
}

provider "aws" {
  region = var.aws_region
}

# ============================
# REDE: VPC, Subnets e Internet Gateway
# ============================
resource "aws_vpc" "crypto_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "crypto-vpc" }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.crypto_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "crypto-public-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.crypto_vpc.id
  tags   = { Name = "crypto-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.crypto_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "crypto-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================
# SECURITY GROUP
# ============================
resource "aws_security_group" "ecs_sg" {
  name        = "crypto-ecs-sg"
  description = "Permite acesso HTTP e ALB"
  vpc_id      = aws_vpc.crypto_vpc.id

  ingress {
    description = "HTTP ALB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "crypto-ecs-sg" }
}

# ============================
# ECR (repositório Docker)
# ============================
resource "aws_ecr_repository" "crypto_api_repo" {
  name                 = "pucrs-crypto-api-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ============================
# ECS CLUSTER
# ============================
resource "aws_ecs_cluster" "crypto_cluster" {
  name = "pucrs-crypto-cluster"
}

# ============================
# IAM ROLE para ECS Task
# ============================
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "crypto-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================
# LOAD BALANCER
# ============================
resource "aws_lb" "crypto_alb" {
  name               = "crypto-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false
  tags = { Name = "crypto-api-alb" }
}

resource "aws_lb_target_group" "crypto_tg" {
  name     = "crypto-api-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.crypto_vpc.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = { Name = "crypto-api-tg" }
}

resource "aws_lb_listener" "crypto_listener" {
  load_balancer_arn = aws_lb.crypto_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.crypto_tg.arn
  }
}

# ============================
# ECS TASK DEFINITION & SERVICE
# ============================
resource "aws_ecs_task_definition" "crypto_task" {
  family                   = var.service_name
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = "${aws_ecr_repository.crypto_api_repo.repository_url}:latest"
    essential = true
    portMappings = [
      { containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }
    ]
  }])
}

resource "aws_ecs_service" "crypto_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.crypto_cluster.id
  task_definition = aws_ecs_task_definition.crypto_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.public_subnets[*].id
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.crypto_tg.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_policy]
}

# ============================
# S3 Bucket para o Front-End (React)
# ============================
resource "aws_s3_bucket" "crypto_ui" {
  bucket = "crypto-ui-${var.aws_region}-${random_id.unique_id.hex}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  tags = {
    Name = "crypto-ui-bucket"
  }
}

# Política para permitir acesso público ao conteúdo do S3
resource "aws_s3_bucket_policy" "crypto_ui_policy" {
  bucket = aws_s3_bucket.crypto_ui.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.crypto_ui.arn}/*"
      }
    ]
  })
}

