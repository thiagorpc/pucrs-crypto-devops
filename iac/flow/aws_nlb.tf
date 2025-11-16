# ============================
# File: ./iac/flow/aws_nlb.tf
# ============================

# Network Load Balancer (NLB) externo para o backend ECS
# Distribui trafego TCP para os targets (IPs do Fargate)
resource "aws_lb" "api_nlb" {
  name               = "${var.project_name}-api-nlb"
  internal           = false               # NLB externo para ser acessado pelo API Gateway
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnets[*].id

  enable_cross_zone_load_balancing = true  # Balanceamento de trafego entre zonas
  tags = {
    Name = "${var.project_name}-api-nlb"
  }
}

# Target Group do NLB configurado por IP
# Fargate registra seus contêineres por IP
resource "aws_lb_target_group" "lb_target_group" {
  name        = "${var.project_name}-api-tg"
  port        = var.container_port        # Porta do contêiner
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  # Health check do serviço
  health_check {
    path                = "/health"        # Endpoint de health check
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 10                # Intervalo entre verificações
    timeout             = 5                 # Timeout da verificação
    healthy_threshold   = 2                 # Quantidade de verificações saudaveis para considerar healthy
    unhealthy_threshold = 2                 # Quantidade de verificações falhas para considerar unhealthy
  }
}

# Listener do NLB
# Recebe conexões na porta TCP e encaminha para o target group
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.api_nlb.arn
  port              = 80                  # Porta do listener
  protocol          = "TCP"               # Pode ser TLS se desejar criptografia no NLB

  # Caso queira TLS, habilite a linha abaixo com ACM
  # certificate_arn = aws_acm_certificate_validation.cert.certificate_arn 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

