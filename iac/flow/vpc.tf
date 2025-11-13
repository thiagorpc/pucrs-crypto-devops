# ============================
# File: ./iac/flow/vpc.tf
# ============================
# REDE: VPC, Subnets e Internet Gateway
# ============================
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "${var.project_name}-public-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================
# SECURITY GROUPS (SEPARADOS POR CAMADA)
# ============================

# 1. Security Group para o NLB (Público, Porta 80)
//resource "aws_security_group" "alb_sg" {
//name        = "crypto-nlb-sg"
//description = "Permite acesso HTTP publico (Porta 80)"
//vpc_id      = aws_vpc.vpc.id
///ingress {
//  description = "HTTP acesso publico"
//  from_port   = 80
//  to_port     = 80
//  protocol    = "tcp"
//  cidr_blocks = ["0.0.0.0/0"]
//}
///  ingress {
//  description = "HTTP acesso publico"
//  from_port   = 443
//  to_port     = 443
//  protocol    = "tcp"
//  cidr_blocks = ["0.0.0.0/0"]
//}
///egress {
//  description = "Acesso Publico"
//  from_port   = 0
//  to_port     = 0
//  protocol    = "-1"
//  cidr_blocks = ["0.0.0.0/0"]
//}
//tags = { Name = "crypto-nlb-sg" }
//}

# 2. Security Group para o ECS (Privado, Porta do Contêiner)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Permite acesso apenas do NLB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Acesso ao NLB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    description = "Acesso Publico"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-ecs-sg" }
}

# ====================================================================================
# Endpoint para comunicação com o AWS SECREET MANAGER
# ====================================================================================
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"

  # Usa as subnets públicas mesmo
  subnet_ids         = aws_subnet.public_subnets[*].id

  # Reutiliza o mesmo SG do ECS ou cria um dedicado
  security_group_ids = [aws_security_group.ecs_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-secretsmanager-endpoint"
  }
}

#resource "aws_vpc_endpoint" "secrets_manager" {
#  vpc_id             = aws_vpc.vpc.id
#  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
#  vpc_endpoint_type  = "Interface"
#  subnet_ids         = aws_subnet.private_subnets[*].id
#  security_group_ids = [aws_security_group.vpc_endpoints.id]
#
#  private_dns_enabled = true
#  tags = {
#    Name = "${var.project_name}-secretsmanager-endpoint"
#  }
#}