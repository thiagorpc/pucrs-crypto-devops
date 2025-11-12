# ============================
# LOAD BALANCER
# ============================
resource "aws_lb" "alb" {
  name                       = "${var.project_name}-api-nlb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false
  tags                       = { Name = "${var.project_name}-api-nlb" }
}

resource "aws_lb_target_group" "lb_target_group" {
  name        = "${var.project_name}-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = { Name = "${var.project_name}-api-tg" }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  
  # 🚨 PONTO CRÍTICO: SUBSTITUA PELA REFERÊNCIA VÁLIDA DO SEU CERTIFICADO
  certificate_arn   = aws_iam_server_certificate.iam_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# Obtém o Load Balancer existente pelo nome fixo
#data "aws_lb" "alb_data" {
#  name = "crypto-api-nlb" 
#  # Nota: Se o NLB ainda não foi criado, você precisará de uma dependência ou garantir que esta consulta só ocorra após a criação.
#}

# 1. Gerar a Chave Privada (crypto-api-key.pem)
resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 2. Gerar o Certificado Autoassinado (Self-Signed)
resource "tls_self_signed_cert" "certificate" {
  # key_algorithm   = "RSA"
  private_key_pem = tls_private_key.tls_key.private_key_pem
  
  # O Common Name deve ser o DNS do seu NLB
  # common_name = data.aws_lb.alb_data.dns_name 

  subject {
    common_name  = "${var.project_name}-api-nlb.poc.local"
    #common_name  = data.aws_lb.alb_data.dns_name
    organization = "Crypto256"
  }

  validity_period_hours = 8760 # 1 ano
  is_ca_certificate     = true
  
  # Permite o uso como certificado de servidor
  allowed_uses = [
    "server_auth",
    "digital_signature",
    "key_encipherment",
  ]
}

# 3. Fazer o Upload do Certificado para o IAM
resource "aws_iam_server_certificate" "iam_cert" {
  name_prefix      = "${var.project_name}-self-signed-"
  certificate_body = tls_self_signed_cert.certificate.cert_pem
  private_key      = tls_private_key.tls_key.private_key_pem

  # 🚨 Nota de dependência: Garante que o Certificado só é criado após a Key/Cert
  lifecycle {
    create_before_destroy = true
  }
}

