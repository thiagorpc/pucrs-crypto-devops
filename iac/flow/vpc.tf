# ============================
# File: ./iac/flow/vpc.tf
# ============================
# REDE: VPC, Subnets e Internet Gateway
# ============================
resource "aws_vpc" "crypto_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "crypto-vpc" }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.crypto_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "crypto-public-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.crypto_vpc.id
  tags   = { Name = "crypto-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.crypto_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "crypto-public-rt" }
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
//vpc_id      = aws_vpc.crypto_vpc.id
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
  name        = "crypto-ecs-sg"
  description = "Permite acesso apenas do NLB"
  vpc_id      = aws_vpc.crypto_vpc.id

  ingress {
    description = "Acesso ao NLB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.crypto_vpc.cidr_block]
  }

  egress {
    description = "Acesso Publico"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "crypto-ecs-sg" }
}