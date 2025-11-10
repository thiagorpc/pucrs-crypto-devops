# ============================
# LOAD BALANCER
# ============================
resource "aws_lb" "crypto_alb" {
  name                       = "crypto-api-alb"
  internal                   = false
  load_balancer_type         = "application"
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