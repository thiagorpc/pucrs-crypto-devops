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

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false # CORRIGIDO: Garante que são privadas.
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "${var.project_name}-private-${count.index}" }
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
# INFRAESTRUTURA DE REDE PRIVADA (NAT Gateway e Rotas)
# ============================

# 1. Endereço IP El astico (EIP) para o NAT Gateway
resource "aws_eip" "nat_gateway" {
  count      = 1
  # vpc = true
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.project_name}-nat-eip" }
}

# 2. Criação do NAT Gateway na Subnet Pública (necess ario para acesso à internet)
resource "aws_nat_gateway" "nat" {
  count         = 1
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags          = { Name = "${var.project_name}-nat-gateway" }
}

# 3. Tabela de Roteamento Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

# 4. Associação da Tabela de Roteamento às Subnets Privadas
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================
# SECURITY GROUPS (SEPARADOS POR CAMADA)
# ============================

# 1. Security Group para o NLB (Público, Porta 80)
// Removido para concisão.

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
    # Regra de tr afego de entrada mais segura: Permite apenas o NLB (assumindo que ele est a na VPC)
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    description = "Acesso Publico"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # OK para Tasks que usam NAT Gateway
  }
  tags = { Name = "${var.project_name}-ecs-sg" }
}

# 3. Security Group para os VPC Endpoints
resource "aws_security_group" "endpoint_sg" {
  name        = "${var.project_name}-endpoint-sg"
  description = "Permite tr afego de entrada do ECS SG para os VPC Endpoints"
  vpc_id      = aws_vpc.vpc.id

  # Ingress: Permite tr afego de entrada do SG do ECS (onde a Task roda)
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  # Egress: Permite todo o tr afego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-endpoint-sg" }
}

# ====================================================================================
# VPC ENDPOINTS DE INTERFACE (INTERFACE ENDPOINTS)
# ====================================================================================

# 1. Endpoint para Secrets Manager (CORRIGIDO: Removido Duplicação)
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-secretsmanager-endpoint" }
}

# 2. Endpoint para CloudWatch Logs (NOVO - Resolve a falha de log stream)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-logs-endpoint" }
}
