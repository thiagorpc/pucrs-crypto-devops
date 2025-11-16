# ============================
# File: ./iac/flow/aws_ecs.tf
# ============================

# ECR (Elastic Container Registry) - repositório para imagens Docker
resource "aws_ecr_repository" "image_repo" {
  name                 = "${var.project_name}-api-repo"
  image_tag_mutability = "MUTABLE"

  # Habilita scan automatico de vulnerabilidades nas imagens
  image_scanning_configuration {
    scan_on_push = true
  }

  # Permite exclusão forçada do repositório
  force_delete = true

  lifecycle {
    prevent_destroy = false
  }
}

# ECS Cluster - grupo lógico de serviços ECS
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-esc-cluster"
}

# CloudWatch Log Group para ECS - armazenamento centralizado de logs
resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/ecs/${var.project_name}-app"
  retention_in_days = 7
}

# Documento de política de confiança para ECS assumir roles
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Task Execution Role - usada pelo ECS para pull de imagens, logs e acesso a secrets
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.project_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Anexa a política gerenciada padrão para Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Política personalizada KMS para descriptografar secrets
resource "aws_iam_policy" "ecs_kms_decrypt_policy" {
  name        = "${var.project_name}-ecs-kms-decrypt-policy"
  description = "Permite que a Task Execution Role use a KMS Key para descriptografar secrets."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/SEU_KMS_KEY_ID_AQUI"
      }
    ]
  })
}

# Política para acesso a Secrets Manager (leitura de secrets)
resource "aws_iam_policy" "ecs_secret_access_policy" {
  name        = "${var.project_name}-ecs-secrets-policy"
  description = "Permite que a Task Execution Role acesse secrets."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = local.encryption_secret_arn
      }
    ]
  })
}

# Anexa a política de secrets à Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_secret_access_attach" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secret_access_policy.arn
}

# Política específica para o Terraform ler um secret da API
resource "aws_iam_policy" "terraform_secrets_read" {
  name        = "TerraformSecretsReadPolicy"
  description = "Permite ao Terraform ler o secret da crypto-api"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:us-east-1:202533542500:secret:pucrs-crypto-api/encryption-key-X6j4JI"
      }
    ]
  })
}

# Anexa a política Terraform ao usuario de automação
resource "aws_iam_user_policy_attachment" "bot_secrets_read_attach" {
  user       = "mitel-message-hub-terraform-github-bot"
  policy_arn = aws_iam_policy.terraform_secrets_read.arn
}

# Task Role - usada pelo código da aplicação para acessar recursos AWS (S3, DynamoDB)
resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Política de acesso ao bucket S3 de imagens (Task Role)
resource "aws_iam_policy" "ecs_s3_access_policy" {
  name        = "${var.project_name}-ecs-s3-access-policy"
  description = "Permite que a Task Role acesse o bucket de imagens."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"],
        Resource = [aws_s3_bucket.images.arn, "${aws_s3_bucket.images.arn}/*"]
      }
    ]
  })
}

# Anexa a política S3 à Task Role
resource "aws_iam_role_policy_attachment" "ecs_s3_access_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access_policy.arn
}

# ECS Task Definition - define containers, roles, secrets e variaveis de ambiente
resource "aws_ecs_task_definition" "task" {
  family       = "${var.project_name}-api"
  cpu          = var.ecs_cpu
  memory       = var.ecs_memory
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]

  # Task Execution Role (para logs, secrets, pull de imagem)
  execution_role_arn = aws_iam_role.task_execution_role.arn
  # execution_role_arn = aws_iam_role.ecs_execution_role.arn
  # Task Role (para acesso S3, usada pelo runtime da aplicação)
  task_role_arn = aws_iam_role.task_role.arn

  container_definitions = jsonencode([{
    name      = "${var.project_name}-api"
    image     = "${aws_ecr_repository.image_repo.repository_url}:${var.image_tag}"
    essential = true
    portMappings = [
      { containerPort = 3000, protocol = "tcp" }
    ]

    secrets = [
      {
        name      = "ENCRYPTION_KEY",
        valueFrom = data.aws_secretsmanager_secret.encryption_key.arn,
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.log.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "NODE_ENV", value = var.project_stage },
      #{ name = "PORT", value = "${var.container_port}" },
      { name = "PORT", value = tostring(var.container_port) },
      { name = "HOST", value = var.container_host },
      { name = "TZ", value = var.container_TZ },
      { name = "IMAGE_BUCKET_NAME", value = aws_s3_bucket.images.bucket },
      { name = "CORS_ORIGIN", value = "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}"  }
    ]
  }])
}

# ECS Service - gerencia execução e balanceamento da task
resource "aws_ecs_service" "fargate" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "${var.project_name}-api"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
    aws_iam_role_policy_attachment.ecs_secret_access_attach,
    aws_iam_role_policy_attachment.ecs_s3_access_attach
  ]
}

# ECR Lifecycle Policy - mantém apenas as ultimas 10 imagens
resource "aws_ecr_lifecycle_policy" "api_cleanup" {
  repository = aws_ecr_repository.image_repo.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Manter as ultimas 10 imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

