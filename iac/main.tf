/*
Autor: Thiago Costa

✅ Este Terraform faz:
  - Cria VPC, subnets públicas e Internet Gateway
  - Cria Security Group permitindo acesso HTTP
  - Cria ECR para armazenar imagens Docker
  - Cria ECS Cluster + Task Definition + Service Fargate
  - Cria IAM Role para ECS
  - Cria ALB + Target Group + Listener
  - Cria Bucket S3 para hospedar o frontend React (modo site)
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ==================================
  # 🚨 CORREÇÃO DE BACKEND
  # ==================================
  backend "s3" {
    bucket = "aws-s3-crypto-github-action-tfstate-unique" # O NOME EXATO do bucket criado acima
    key    = "terraform.tfstate"                          # Caminho do arquivo de estado dentro do bucket
    region = "us-east-1"
    encrypt = true
    
    # ❗️ CORREÇÃO: Adicionado state locking com DynamoDB
    # (Lembre-se de criar manualmente esta tabela com a Primary Key "LockID")
    dynamodb_table = "terraform-lock-table-crypto"
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================
# VARIÁVEIS
# (Centralizadas aqui para facilitar a configuração)
# ============================
variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de blocos CIDR para as subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "container_port" {
  description = "Porta que o contêiner expõe"
  type        = number
  default     = 8080 # ❗️ Exemplo: ajuste para a porta da sua API (ex: 8080, 5000, 3000)
}

variable "service_name" {
  description = "Nome do serviço ECS e Task"
  type        = string
  default     = "crypto-api-service"
}

variable "image_tag" {
  description = "A tag da imagem Docker a ser usada (ex: o Git SHA)"
  type        = string
  default     = "latest" # Padrão para testes locais
}


# ============================
# ID aleatório para S3
# ============================
resource "random_id" "unique_id" {
  byte_length = 8
}

# ============================
# REDE: VPC, Subnets e Internet Gateway
# ============================
resource "aws_vpc" "crypto_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "crypto-vpc" }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.crypto_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "crypto-public-${count.index}" }
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
# 🚨 CORREÇÃO DE SECURITY GROUP
# (Dividido em 2 SGs: 1 para ALB, 1 para ECS)
# ============================

# 1. Security Group para o ALB (Público, Porta 80)
resource "aws_security_group" "alb_sg" {
  name        = "crypto-alb-sg"
  description = "Permite acesso HTTP publico (Porta 80)"
  vpc_id      = aws_vpc.crypto_vpc.id

  ingress {
    description = "HTTP acesso publico"
    from_port   = 80 # ❗️ Apenas porta 80
    to_port     = 80 # ❗️ Apenas porta 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Saída total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "crypto-alb-sg" }
}

# 2. Security Group para o ECS (Privado, Porta do Contêiner)
resource "aws_security_group" "ecs_sg" {
  name        = "crypto-ecs-sg"
  description = "Permite acesso apenas do ALB"
  vpc_id      = aws_vpc.crypto_vpc.id

  ingress {
    description = "Acesso do ALB"
    from_port   = var.container_port # ❗️ Porta da aplicação
    to_port     = var.container_port # ❗️ Porta da aplicação
    protocol    = "tcp"
    # ❗️ Permite tráfego APENAS do Security Group do ALB
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Saída total"
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

  lifecycle {
    prevent_destroy = false
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
  name                       = "crypto-api-alb"
  internal                   = false
  load_balancer_type         = "application"
  # ❗️ CORREÇÃO: Usando o SG do ALB
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false
  tags                       = { Name = "crypto-api-alb" }
}

resource "aws_lb_target_group" "crypto_tg" {
  name        = "crypto-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.crypto_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health" # ❗️ Verifique se este é o path correto da sua API
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
    # ❗️ CORREÇÃO: Usando a variável 'image_tag'
    image     = "${aws_ecr_repository.crypto_api_repo.repository_url}:${var.image_tag}"
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
    subnets = aws_subnet.public_subnets[*].id
    # ❗️ CORREÇÃO: Usando o SG do ECS
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
# S3 para Frontend React
# ============================
resource "aws_s3_bucket" "crypto_ui" {
  bucket = "crypto-ui-${var.aws_region}-${random_id.unique_id.hex}"
  tags   = { Name = "crypto-ui-bucket" }
}

resource "aws_s3_bucket_ownership_controls" "crypto_ui_ownership" {
  bucket = aws_s3_bucket.crypto_ui.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "crypto_ui_website" {
  bucket = aws_s3_bucket.crypto_ui.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
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

# ============================
# 🏛️ OUTPUTS (Saídas)
# (Adicionado para saber os endereços criados)
# ============================

output "api_load_balancer_dns" {
  description = "DNS público do Load Balancer (API)"
  value       = aws_lb.crypto_alb.dns_name
}

output "frontend_s3_website_url" {
  description = "URL do site S3 (Frontend)"
  value       = aws_s3_bucket_website_configuration.crypto_ui_website.website_endpoint
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.crypto_api_repo.repository_url
}