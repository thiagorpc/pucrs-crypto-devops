# ============================
# File: ./iac/nlb.tf
# ============================

# NLB (Network Load Balancer)
resource "aws_lb" "crypto_api_nlb" {
  name               = "crypto-api-nlb"
  internal           = false # Deve ser externo se o API GW o acessa externamente
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnets[*].id

  enable_cross_zone_load_balancing = true
  tags                             = { Name = "crypto-api-nlb" }
}

# Target Group do NLB (por IP)
resource "aws_lb_target_group" "crypto_tg" {
  name        = "crypto-nlb-tg"
  port        = var.container_port # Porta do contêiner (ex: 3000)
  protocol    = "TCP"
  vpc_id      = aws_vpc.crypto_vpc.id
  target_type = "ip" # Fargate usa IP

  health_check {
    path                = "/health" # Verifique se esta é sua rota de saúde
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener do NLB (Porta 443 ou 80)
resource "aws_lb_listener" "crypto_nlb_listener" {
  load_balancer_arn = aws_lb.crypto_api_nlb.arn
  port              = 80
  protocol          = "TCP" # 🎯 Usar TLS se você quer criptografia no NLB

  # Você precisa de um certificado ACM para Terminação TLS no NLB
  # certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.crypto_tg.arn
  }
}