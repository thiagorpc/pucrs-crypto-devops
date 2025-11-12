# ============================
# File: ./iac/flow/ecs.tf
# ============================

# ============================
# ECR (repositório Docker)
# ============================
resource "aws_ecr_repository" "crypto_api_repo" {
  name                 = "pucrs-crypto-api-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

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
# CLOUDWATCH LOGS
# ============================
resource "aws_cloudwatch_log_group" "crypto_app" {
  name              = "/ecs/crypto-app"
  retention_in_days = 7
}

# ============================
# IAM ROLES E POLÍTICAS DE ACESSO
# ============================

# Documento de política de confiança para que o ECS assuma as roles
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

# 1. IAM ROLE: Task Execution Role (Usada pelo agente ECS para pull de imagem, logs e secrets)
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "crypto-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Anexa a política gerenciada padrão para Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Política para permitir acesso ao Secrets Manager (Anexada à Execution Role)
resource "aws_iam_policy" "ecs_secret_access_policy" {
  name        = "crypto-ecs-secrets-policy"
  description = "Permite que a Task Execution Role acesse a chave de criptografia."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        # ⚠️ Ajuste o ARN abaixo. O '*' cobre versões do secret.
        Resource = var.secrets_encryption_key,
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secret_access_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secret_access_policy.arn
}


# 2. IAM ROLE: Task Role (Usada pelo código da aplicação para acessar recursos AWS, como S3/DynamoDB)
resource "aws_iam_role" "crypto_task_role" {
  name               = "crypto-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Política para permitir acesso ao S3 de imagens (Anexada à Task Role)
resource "aws_iam_policy" "ecs_s3_access_policy" {
  name        = "crypto-ecs-s3-access-policy"
  description = "Permite que a Task Role acesse o bucket de imagens."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.crypto_images.arn,
          "${aws_s3_bucket.crypto_images.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access_attach" {
  role       = aws_iam_role.crypto_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access_policy.arn
}

# ============================
# ECS TASK DEFINITION & SERVICE
# ============================
resource "aws_ecs_task_definition" "crypto_task" {
  family       = var.service_name
  cpu          = var.ecs_cpu
  memory       = var.ecs_memory
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]

  # Task Execution Role (para logs, secrets, pull de imagem)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  # Task Role (para acesso S3, usada pelo runtime da aplicação)
  task_role_arn = aws_iam_role.crypto_task_role.arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = "${aws_ecr_repository.crypto_api_repo.repository_url}:${var.image_tag}"
    essential = true
    portMappings = [
      { containerPort = 3000, protocol = "tcp" }
    ]

    secrets = [
      {
        name      = "ENCRYPTION_KEY",
        valueFrom = var.secrets_encryption_key,
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.crypto_app.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = "3000" },
      { name = "HOST", value = "0.0.0.0" },
      { name = "TZ", value = "America/Sao_Paulo" },
      { name = "IMAGE_BUCKET_NAME", value = aws_s3_bucket.crypto_images.bucket }
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
    subnets          = aws_subnet.public_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.crypto_api_tg.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  #load_balancer {
  #  target_group_arn = aws_lb_target_group.crypto_api_tg.arn
  #  container_name   = var.service_name
  #  container_port   = var.container_port
  #}

  # Dependências explícitas (garantindo que as roles estejam prontas)
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
    aws_iam_role_policy_attachment.ecs_secret_access_attach,
    aws_iam_role_policy_attachment.ecs_s3_access_attach
  ]
}


# ====================================================================================
# ECR LIFECYCLE POLICY (Limpeza de Imagens)
# ====================================================================================
resource "aws_ecr_lifecycle_policy" "crypto_api_cleanup" {
  repository = aws_ecr_repository.crypto_api_repo.name

  policy = jsonencode({
    rules = [
      {
        # Regra 1: Manter as últimas 10 imagens mais recentes (por contagem)
        "rulePriority" : 1,
        "description" : "Manter as últimas 10 imagens",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 10
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}