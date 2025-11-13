# ============================
# File: ./iac/flow/ecs.tf
# ============================

# ============================
# ECR (repositório Docker)
# ============================
resource "aws_ecr_repository" "image_repo" {
  name                 = "${var.project_name}-api-repo"
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
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-esc-cluster"
}

# ============================
# CLOUDWATCH LOGS
# ============================
resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/ecs/${var.project_name}-app"
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
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.project_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Anexa a política gerenciada padrão para Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Adiciona permissão de Decrypt na KMS Key (substitua o ARN da chave real)
resource "aws_iam_policy" "ecs_kms_decrypt_policy" {
  name        = "${var.project_name}-ecs-kms-decrypt-policy"
  description = "Permite que a Task Execution Role use a KMS Key para descriptografar secrets."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["kms:Decrypt"],
        // ⚠️ Substitua "arn:aws:kms:..." pela ARN da sua chave KMS
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/SEU_KMS_KEY_ID_AQUI" 
      },
    ]
  })
}

# Política para permitir acesso ao Secrets Manager (Anexada à Execution Role)
resource "aws_iam_policy" "ecs_secret_access_policy" {
  name        = "${var.project_name}-ecs-secrets-policy"
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
        Resource = local.encryption_secret_arn,
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secret_access_attach" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secret_access_policy.arn
}

resource "aws_iam_policy" "terraform_secrets_read" {
  name        = "TerraformSecretsReadPolicy"
  description = "Permite ao Terraform ler o secret da crypto-api"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:us-east-1:202533542500:secret:pucrs-crypto-api/encryption-key-X6j4JI"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "bot_secrets_read_attach" {
  user       = "mitel-message-hub-terraform-github-bot"
  policy_arn = aws_iam_policy.terraform_secrets_read.arn
}


# 2. IAM ROLE: Task Role (Usada pelo código da aplicação para acessar recursos AWS, como S3/DynamoDB)
resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Política para permitir acesso ao S3 de imagens (Anexada à Task Role)
resource "aws_iam_policy" "ecs_s3_access_policy" {
  name        = "${var.project_name}-ecs-s3-access-policy"
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
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access_policy.arn
}

# ============================
# ECS TASK DEFINITION & SERVICE
# ============================
resource "aws_ecs_task_definition" "task" {
  family       = "${var.project_name}-api" #"Nome do serviço ECS que será executado no Fargate."
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
      { name = "PORT", value = "${var.container_port}" },
      { name = "HOST", value = var.container_host },
      { name = "TZ", value = var.container_TZ },
      { name = "IMAGE_BUCKET_NAME", value = aws_s3_bucket.images.bucket }
    ]
  }])
}

resource "aws_ecs_service" "fargate" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "${var.project_name}-api"
    container_port   = var.container_port
  }

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
resource "aws_ecr_lifecycle_policy" "api_cleanup" {
  repository = aws_ecr_repository.image_repo.name

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
