# Changelog – root_eft (EFT-OscarLeiva)

Todos los cambios notables en este proyecto serán documentados en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [4.0.0] - 2026-07-08

### Added
- Repositorios individuales `vpc_eft`, `ec2_eft` y `terraform-aws-backend-EFT`, separados del
  repositorio grupal original para la entrega individual de la EFT.
- Rama de trabajo `feat/eft-individual-oscar-leiva` para desarrollar y validar los cambios de
  forma aislada antes de integrarlos a `main`.
- Outputs adicionales `nat_gateway_id`, `public_subnet_ids` y `private_subnet_ids` en `outputs.tf`.

### Changed
- **BREAKING:** `main.tf` actualizado para consumir los módulos individuales:
  `github.com/olcduoc/vpc_eft?ref=v2.0.0` y `github.com/olcduoc/ec2_eft?ref=v1.0.0`
  (en lugar de los repositorios grupales `terraform-aws-vpc-AUY1105-grupo-1` /
  `terraform-aws-ec2-AUY1105-grupo-1`).
- Backend remoto migrado a recursos propios: bucket `eft-oleivac-tfstate` y tabla
  `eft-oleivac-tfstate-lock` (antes `auy1105-grupo1-tfstate` / `auy1105-grupo1-tfstate-lock`,
  compartidos con el grupo).
- Workflow renombrado de `AUY1105-GRUPO-Nro1.yml` a `root_eft.yml`; nombre del pipeline
  actualizado a "DevSecOps Pipeline – root_eft".
- `variables.tf`: valor por defecto de `project_name` actualizado a `"EFT-OscarLeiva"`.
- `README.md` reescrito para reflejar la arquitectura, IDs de recursos y repositorios propios
  del entregable individual.

### Fixed
- Mantenido `dynamodb_table` (en vez de `use_lockfile`) en el bloque `backend "s3"` de
  `versions.tf`, por compatibilidad con el `required_version = ">= 1.5.0"` declarado en el
  proyecto — `use_lockfile` no está disponible en esa línea de versión mínima soportada,
  independientemente de la versión del binario Terraform usada localmente para desarrollo.

### Migration Guide
```bash
# Paso 1: crear recursos del backend individual (estado local, proyecto aparte)
cd terraform-aws-backend-EFT
terraform init && terraform apply

# Paso 2: en root_eft, reconfigurar el backend hacia el nuevo bucket/tabla
cd ../root_eft
terraform init -reconfigure

# Paso 3: verificar que no hay drift
terraform plan
```

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
- Workflow reorganizado en 2 jobs con generación de evidencias.

> **Nota (v4.0.0):** los nombres de bucket/tabla de esta entrada corresponden al backend
> compartido del repositorio grupal original. En la versión individual (`v4.0.0`) estos recursos
> fueron reemplazados por `eft-oleivac-tfstate` / `eft-oleivac-tfstate-lock`.

## [2.0.0] - 2026-05-28

### Added
- Archivo `main.tf` que orquesta los módulos `redes` y `computo` (EVA2).
- Archivo `variables.tf` con variables parametrizadas para el repositorio principal.
- Archivo `outputs.tf` con outputs consolidados de ambos módulos.
- Archivo `versions.tf` con configuración del provider AWS y versión Terraform.
- Integración con módulo redes `vpc_eft` v1.0.0.
- Integración con módulo cómputo `ec2_eft` v1.0.0.

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
