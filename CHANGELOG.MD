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
