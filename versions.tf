# ─────────────────────────────────────────────────────────────
# versions.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
