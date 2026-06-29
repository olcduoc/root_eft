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
  default     = "181.43.52.214/32"
}

variable "project_name" {
  description = "Nombre base del proyecto para etiquetar los recursos."
  type        = string
  default     = "AUY1105-GRUPO-Nro1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}