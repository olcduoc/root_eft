# Changelog – AUY1105-GRUPO-Nro1

Todos los cambios notables en este proyecto serán documentados en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [3.0.0] - 2026-06-28

### Added
- Backend remoto S3 (`auy1105-grupo1-tfstate`) con cifrado AES-256 y versionado habilitado.
- Tabla DynamoDB (`auy1105-grupo1-tfstate-lock`) para bloqueo de estado concurrente.
- Archivo `bootstrap_backend.tf` para crear los recursos del backend antes de la migración.
- Soporte Multi-AZ: subredes públicas y privadas en `us-east-1a` y `us-east-1b`.
- NAT Gateway para tráfico saliente desde subredes privadas.
- Route Tables diferenciadas por tipo de subred (pública / privada).
- Job `terraform-apply` en el pipeline CI/CD con captura de outputs y generación de evidencia.
- Generación automática de evidencia en Markdown (`evidencia_pipeline.md`, `evidencia_apply.md`).
- Comentario automático de evidencia en Pull Requests mediante `actions/github-script`.
- Subida de artefactos de evidencia con retención de 30 días (`actions/upload-artifact@v4`).
- Archivo `EVIDENCIAS_EFT126.md` con evidencias consolidadas por criterio de rúbrica.

### Changed
- Módulos referenciados por **tag semántico** `v1.0.0` en lugar de commit hash.
- `versions.tf` actualizado con bloque `backend "s3"`.
- `variables.tf` con variables adicionales para región, bucket y tabla DynamoDB.
- `outputs.tf` con outputs de subredes privadas y NAT Gateway.
- Workflow `AUY1105-GRUPO-Nro1.yml` reorganizado en 2 jobs con generación de evidencias.

### Migration Guide
```bash
# Paso 1: crear recursos del backend (estado local)
terraform init && terraform apply  # con bootstrap_backend.tf presente

# Paso 2: migrar estado al backend remoto
terraform init -migrate-state

# Paso 3: eliminar bootstrap_backend.tf del directorio
```

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
