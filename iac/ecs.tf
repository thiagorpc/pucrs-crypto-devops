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