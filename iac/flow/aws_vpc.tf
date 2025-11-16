# ============================
# File: ./iac/flow/aws_vpc.tf
# ============================

# ============================
# VPC principal
# ============================
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# Captura zonas de disponibilidade disponíveis
data "aws_availability_zones" "available" {}

# ============================
# Subnets publicas
# ============================
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "${var.project_name}-public-${count.index}" }
}

# ============================
# Subnets privadas
# ============================
resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "${var.project_name}-private-${count.index}" }
}

# ============================
# Internet Gateway para acesso publico
# ============================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ============================
# Tabela de roteamento publica
# ============================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# Associação da tabela de roteamento às subnets publicas
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================
# NAT Gateway e tabelas privadas
# ============================

# Elastic IP para NAT Gateway
resource "aws_eip" "nat_gateway" {
  count      = 1
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.project_name}-nat-eip" }
}

# NAT Gateway para permitir que subnets privadas acessem a internet
resource "aws_nat_gateway" "nat" {
  count         = 1
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags          = { Name = "${var.project_name}-nat-gateway" }
}

# Tabela de roteamento privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

# Associação da tabela de roteamento às subnets privadas
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================
# Security Groups
# ============================

# Security Group para ECS (apenas trafego do NLB permitido)
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
    description = "Acesso publico via NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-sg" }
}

# Security Group para VPC Endpoints
resource "aws_security_group" "endpoint_sg" {
  name        = "${var.project_name}-endpoint-sg"
  description = "Permite trafego do ECS SG para VPC Endpoints"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-endpoint-sg" }
}

# ============================
# VPC Interface Endpoints
# ============================

# Endpoint Secrets Manager
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-secretsmanager-endpoint" }
}

# Endpoint CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-logs-endpoint" }
}

# Endpoint ECR API (Autenticação)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-ecr-api-endpoint" }
}

# Endpoint ECR DKR (Docker Pull)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-ecr-dkr-endpoint" }
}

