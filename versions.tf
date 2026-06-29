# ─────────────────────────────────────────────────────────────
# versions.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# Gobernanza de Estado: backend remoto S3 + DynamoDB (EVA3)
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "auy1105-grupo1-tfstate"
    key            = "main/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "auy1105-grupo1-tfstate-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
