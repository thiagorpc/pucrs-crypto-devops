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
# ECS TASK DEFINITION & SERVICE
# ============================
resource "aws_ecs_task_definition" "crypto_task" {
  family                   = var.service_name
  cpu                      = var.ecs_cpu        # 🔄 Usando variável
  memory                   = var.ecs_memory     # 🔄 Usando variável
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = "${aws_ecr_repository.crypto_api_repo.repository_url}:${var.image_tag}" # 🔄 Usando variável
    essential = true
    portMappings = [
      { containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }
    ]

    secrets = [
      {
        name = "ENCRYPTION_KEY", # O nome da variável que sua aplicação espera

        # ⚠️ SUBSTITUA PELO ARN COMPLETO DO SEU SECRET
        valueFrom = "arn:aws:secretsmanager:us-east-1:202533542500:secret:crypto-api/encryption-key-kGeYT2" 
      }
    ]


    environment = [
      # Variáveis Simples (Diretamente Injetadas)
      {
        name  = "NODE_ENV",
        value = "production"
      },
      {
        name  = "PORT",
        value = "3000" # Use var.container_port se preferir
      },
      {
        name  = "HOST",
        value = "0.0.0.0"
      },
      {
        name  = "TZ",
        value = "America/Sao_Paulo"
      },
      # Variável do bucket de imagens (mantida)
      {
        name  = "IMAGE_BUCKET_NAME",
        value = aws_s3_bucket.crypto_images.bucket
      }
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

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
    aws_iam_role_policy_attachment.ecs_secret_access_attach
  ]
}

# Define a política para acesso ao Secrets Manager
resource "aws_iam_policy" "ecs_secret_access_policy" {
  name        = "crypto-ecs-secrets-policy"
  description = "Permite que a Task Execution Role acesse a chave de criptografia."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
        ],
        Resource = "arn:aws:secretsmanager:us-east-1:202533542500:secret:crypto-api/encryption-key-kGeYT2*", 
        # ⚠️ Ajuste o ARN acima. O '*' no final é para cobrir versões do secret -- :-)
      },
    ]
  })
}

# ============================
# Política de acesso ao Secret
# ============================
resource "aws_iam_role_policy_attachment" "ecs_secret_access_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secret_access_policy.arn
}


# ====================================================================================
# Política para excluir imagens antigas que estão no Amazon Elastic Container Registry
# ====================================================================================
resource "aws_ecr_lifecycle_policy" "crypto_api_cleanup" {
  repository = aws_ecr_repository.crypto_api_repo.name

  policy = jsonencode({
    rules = [
      {
        # Regra 1: Manter a tag :latest e as últimas 10 imagens mais recentes (por contagem)
        "rulePriority": 1,
        "description": "Manter as últimas 10 imagens",
        "selection": {
          "tagStatus": "any", # Aplica-se a todas as imagens, exceto as sem tag (untagged)
          "countType": "imageCountMoreThan",
          "countNumber": 10
        },
        "action": {
          "type": "expire" # Ação: Expirar/Deletar
        }
      },
      {
        # Regra 2: Deletar qualquer imagem (com ou sem tag) mais antiga que 90 dias
        "rulePriority": 2,
        "description": "Deletar imagens mais antigas que 90 dias",
        "selection": {
          "tagStatus": "any", 
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 90
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  })
}