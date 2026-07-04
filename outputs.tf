# ─────────────────────────────────────────────────────────────
# outputs.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID de la VPC creada por el módulo redes."
  value       = module.redes.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes PÚBLICAS (Multi-AZ) creadas por el módulo redes."
  value       = module.redes.subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes PRIVADAS (Multi-AZ) creadas por el módulo redes."
  value       = module.redes.private_subnet_ids
}

output "security_group_id" {
  description = "ID del Security Group creado por el módulo redes."
  value       = module.redes.security_group_id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway para tráfico saliente desde subredes privadas."
  value       = module.redes.nat_gateway_id
}

output "instance_id" {
  description = "ID de la instancia EC2 creada por el módulo cómputo."
  value       = module.computo.instance_id
}

output "instance_ip" {
  description = "IP pública de la instancia EC2 creada por el módulo cómputo."
  value       = module.computo.instance_ip
}
