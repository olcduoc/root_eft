#!/bin/bash
# ─────────────────────────────────────────────────────────────
# update_main_repo.sh
# Actualiza el repositorio principal AUY1105-GRUPO-Nro1
# para orquestar los módulos de redes y cómputo (EVA2)
# IMPORTANTE: Ejecutar desde dentro del repositorio clonado
#   cd AUY1105-GRUPO-Nro1
#   bash ../update_main_repo.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

echo "=============================="
echo "Actualizando repositorio principal"
echo "AUY1105-GRUPO-Nro1"
echo "=============================="

# ── Eliminar archivos que se reemplazan por módulos ───────────
echo "[1/6] Eliminando archivos monolíticos reemplazados por módulos..."
rm -f vpc.tf
rm -f ec2.tf
rm -f provider.tf
echo "      vpc.tf, ec2.tf, provider.tf eliminados."

# ── versions.tf ───────────────────────────────────────────────
echo "[2/6] Creando versions.tf..."
cat > versions.tf << 'EOF'
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
EOF

# ── variables.tf ──────────────────────────────────────────────
echo "[3/6] Creando variables.tf..."
cat > variables.tf << 'EOF'
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
EOF

# ── main.tf ───────────────────────────────────────────────────
echo "[4/6] Creando main.tf con llamada a módulos..."
cat > main.tf << 'EOF'
# ─────────────────────────────────────────────────────────────
# main.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# Orquesta los módulos de redes y cómputo (EVA2)
# ─────────────────────────────────────────────────────────────

module "redes" {
  source = "github.com/osleivac/terraform-aws-vpc-AUY1105-grupo-1?ref=v1.0.0"

  project_name        = var.project_name
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24"]
  availability_zones  = ["us-east-1a"]
  ssh_allowed_cidr    = var.ssh_allowed_cidr
}

module "computo" {
  source = "github.com/osleivac/terraform-aws-ec2-AUY1105-grupo-1?ref=v1.0.0"

  project_name      = var.project_name
  subnet_id         = module.redes.subnet_ids[0]
  security_group_id = module.redes.security_group_id
  public_key        = var.public_key
  instance_type     = "t2.micro"
  volume_size       = 8
  volume_type       = "gp3"
  user_data_script  = "${path.module}/install.sh"
}
EOF

# ── outputs.tf ────────────────────────────────────────────────
echo "[5/6] Creando outputs.tf..."
cat > outputs.tf << 'EOF'
# ─────────────────────────────────────────────────────────────
# outputs.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID de la VPC creada por el módulo redes."
  value       = module.redes.vpc_id
}

output "subnet_ids" {
  description = "IDs de las subredes públicas creadas por el módulo redes."
  value       = module.redes.subnet_ids
}

output "security_group_id" {
  description = "ID del Security Group creado por el módulo redes."
  value       = module.redes.security_group_id
}

output "instance_id" {
  description = "ID de la instancia EC2 creada por el módulo cómputo."
  value       = module.computo.instance_id
}

output "instance_ip" {
  description = "IP pública de la instancia EC2 creada por el módulo cómputo."
  value       = module.computo.instance_ip
}
EOF

# ── README.md actualizado ─────────────────────────────────────
echo "[6/6] Actualizando README.md y CHANGELOG.md..."
cat > README.md << 'EOF'
# AUY1105-GRUPO-Nro1: Automatización, Calidad y Seguridad en IaC

## Repositorio GitHub
https://github.com/osleivac/AUY1105-GRUPO-Nro1.git

---

## 1. Descripción del Proyecto

Este repositorio es el **punto de entrada principal** de la infraestructura como código del grupo 1.
Orquesta los módulos de redes y cómputo desarrollados en la Evaluación Parcial N°2, manteniendo
el pipeline de automatización CI/CD implementado en la Evaluación Parcial N°1.

---

## 2. Objetivos

- Orquestar módulos Terraform reutilizables para redes y cómputo en AWS.
- Mantener el pipeline CI/CD con TFLint, Checkov y Terraform Validate.
- Garantizar el cumplimiento de políticas de seguridad mediante OPA.
- Aplicar buenas prácticas de trabajo colaborativo mediante Pull Requests documentados.

---

## 3. Arquitectura de Módulos

```
AUY1105-GRUPO-Nro1 (Repositorio Principal)
├── module "redes"   → terraform-aws-vpc-AUY1105-grupo-1
│   ├── VPC (10.1.0.0/16)
│   ├── Internet Gateway
│   ├── Subnet pública (10.1.1.0/24)
│   ├── Route Table
│   └── Security Group (SSH restringido)
│
└── module "computo" → terraform-aws-ec2-AUY1105-grupo-1
    ├── AMI Ubuntu 24.04 LTS
    ├── Key Pair SSH
    └── EC2 t2.micro (IMDSv2, disco cifrado)
```

---

## 4. Módulos Utilizados

| Módulo   | Repositorio                                                                          | Versión |
|----------|--------------------------------------------------------------------------------------|---------|
| Redes    | [terraform-aws-vpc-AUY1105-grupo-1](https://github.com/osleivac/terraform-aws-vpc-AUY1105-grupo-1) | v1.0.0  |
| Cómputo  | [terraform-aws-ec2-AUY1105-grupo-1](https://github.com/osleivac/terraform-aws-ec2-AUY1105-grupo-1) | v1.0.0  |

---

## 5. Pipeline de Automatización (GitHub Actions)

El workflow se activa automáticamente ante cualquier **Pull Request** hacia la rama `main`:

1. **Análisis Estático (TFLint):** Verifica errores de sintaxis y mejores prácticas de Terraform.
2. **Análisis de Seguridad (Checkov):** Escanea el código en busca de vulnerabilidades.
3. **Validación (Terraform Validate):** Asegura que los archivos `.tf` sean consistentes.

---

## 6. Políticas de Seguridad (OPA)

| Política                  | Descripción                                          |
|---------------------------|------------------------------------------------------|
| `terraform_ssh_check.rego`| Bloquea acceso SSH público (0.0.0.0/0)               |
| `terraform_ec2_check.rego`| Solo permite instancias de tipo `t2.micro`           |

---

## 7. Variables requeridas

| Variable          | Descripción                                     |
|-------------------|-------------------------------------------------|
| `public_key`      | Clave pública SSH (GitHub Secret: TF_VAR_PUBLIC_KEY) |
| `ssh_allowed_cidr`| IP autorizada para SSH (default: `181.43.52.214/32`) |
| `project_name`    | Nombre base del proyecto (default: `AUY1105-GRUPO-Nro1`) |

---

## 8. Instrucciones de Uso

```bash
# 1. Clonar el repositorio
git clone https://github.com/osleivac/AUY1105-GRUPO-Nro1.git
cd AUY1105-GRUPO-Nro1

# 2. Inicializar Terraform (descarga los módulos)
terraform init

# 3. Validar el plan
terraform plan -var="public_key=TU_CLAVE_PUBLICA"

# 4. Los cambios deben proponerse mediante Pull Request hacia main
```

---

**Integrantes:** Juan Pablo - Oscar Leiva
**Docente:** Camilo Jerez
**Institución:** Duoc UC - 2026
EOF

# ── CHANGELOG.md actualizado ──────────────────────────────────
cat > CHANGELOG.md << 'EOF'
# Changelog – AUY1105-GRUPO-Nro1

Todos los cambios notables en este proyecto serán documentados en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-05-28

### Added
- Archivo `main.tf` que orquesta los módulos `redes` y `computo` (EVA2).
- Archivo `variables.tf` con variables parametrizadas para el repositorio principal.
- Archivo `outputs.tf` con outputs consolidados de ambos módulos.
- Archivo `versions.tf` con configuración del provider AWS y versión Terraform.
- Integración con módulo redes `terraform-aws-vpc-AUY1105-grupo-1` v1.0.0.
- Integración con módulo cómputo `terraform-aws-ec2-AUY1105-grupo-1` v1.0.0.

### Changed
- Arquitectura migrada de código monolítico a módulos desacoplados.
- README.md actualizado para reflejar la nueva arquitectura modular.

### Removed
- Archivos monolíticos `vpc.tf`, `ec2.tf` y `provider.tf` reemplazados por módulos.

## [1.0.0] - 2026-04-08

### Added
- Infraestructura base con archivos `ec2.tf`, `vpc.tf`, `provider.tf`.
- Workflow GitHub Actions con etapas TFLint, Checkov y Terraform Validate.
- Políticas OPA para restringir tipo de instancia y bloquear SSH público.
- Documentación inicial en README.md.
- Archivo `.gitignore` para excluir archivos temporales de Terraform.

### Changed
- Nomenclatura de recursos actualizada al formato oficial del curso.

### Fixed
- Resolución de conflictos de archivos locales al sincronizar el repositorio.
EOF

# ── Resumen ───────────────────────────────────────────────────
echo ""
echo "=============================="
echo "Repositorio principal actualizado"
echo "=============================="
echo ""
echo "Archivos modificados/creados:"
echo "  ✅ main.tf        (orquesta módulos redes y cómputo)"
echo "  ✅ variables.tf   (variables parametrizadas)"
echo "  ✅ outputs.tf     (outputs consolidados)"
echo "  ✅ versions.tf    (provider y versión Terraform)"
echo "  ✅ README.md      (documentación actualizada EVA2)"
echo "  ✅ CHANGELOG.md   (versión 2.0.0 registrada)"
echo ""
echo "Archivos eliminados:"
echo "  🗑  vpc.tf"
echo "  🗑  ec2.tf"
echo "  🗑  provider.tf"
echo ""
echo "Archivos sin cambios:"
echo "  ✔  install.sh"
echo "  ✔  .gitignore"
echo "  ✔  terraform_ssh_check.rego"
echo "  ✔  terraform_ec2_check.rego"
echo "  ✔  .github/workflows/ (workflow CI sin cambios)"
echo ""
echo "Próximos pasos:"
echo "  1. git checkout -b feat/modular-architecture"
echo "  2. git add ."
echo "  3. git commit -m 'feat: migración a arquitectura modular EVA2 v2.0.0'"
echo "  4. git push origin feat/modular-architecture"
echo "  5. Abrir Pull Request hacia main en GitHub"
