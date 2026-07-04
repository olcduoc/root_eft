# ─────────────────────────────────────────────────────────────
# variables.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# ─────────────────────────────────────────────────────────────

variable "public_key" {
  description = "Clave pública SSH inyectada por pipeline para acceso a la instancia EC2."
  type        = string
  sensitive   = true
}

variable "ssh_allowed_cidr" {
  description = "CIDR IP autorizado para acceso SSH. No usar 0.0.0.0/0."
  type        = string
  default     = "186.10.98.147/32"
}

variable "project_name" {
  description = "Nombre base del proyecto para etiquetar los recursos."
  type        = string
  default     = "AUY1105-GRUPO-Nro1"
}

variable "aws_region" {
  description = "Región AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "tfstate_bucket" {
  description = "Nombre del bucket S3 para almacenar el estado remoto de Terraform."
  type        = string
  default     = "auy1105-grupo1-tfstate"
}

variable "tfstate_dynamodb_table" {
  description = "Nombre de la tabla DynamoDB para el lock del estado de Terraform."
  type        = string
  default     = "auy1105-grupo1-tfstate-lock"
}

variable "private_subnet_cidrs" {
  description = "Lista de bloques CIDR para las subredes privadas."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Si true, crea un NAT Gateway para las subredes privadas."
  type        = bool
  default     = false
}
