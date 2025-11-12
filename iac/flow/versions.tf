# ============================
# File: ./iac/flow/versions.tf
# ============================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 🔸 O backend foi removido daqui para ser carregado dinamicamente via:
  #     terraform init -backend-config=backend.hcl
}

provider "aws" {
  region = var.aws_region
}
