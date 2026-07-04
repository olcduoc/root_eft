# Informe de Evidencias EFT126 – AUY1105-GRUPO-Nro1

**Fecha:** 2026-06-28
**Integrantes:** Juan Pablo · Oscar Leiva
**Docente:** Camilo Jerez
**Institución:** Duoc UC – 2026
**Repositorio:** https://github.com/olcduoc/AUY1105-GRUPO-Nro1

---

## Resumen de Criterios y Estado

| # | Criterio de Rúbrica | Pond. | Estado EVA2 | Estado EVA3 |
|---|---------------------|-------|-------------|-------------|
| 1 | Diseño e Implementación de Red y HA | 20% | ❌ Single-AZ | ✅ Multi-AZ |
| 2 | Modularización y Calidad del Código | 20% | ✅ Módulos | ✅ Sin cambios |
| 3 | Gobernanza de Estado | 15% | ❌ Local | ✅ S3 + DynamoDB |
| 4 | Pipeline CI/CD y Automatización | 15% | ⚠️ Sin evidencia | ✅ Con evidencia |
| 5 | Versionado Semántico de Módulos | 10% | ❌ Hash | ✅ Tags v1.0.0 |
| 6 | Presentación y Defensa Oral | 20% | ⏳ Pendiente | ⏳ Pendiente |

---

## Criterio 1 – Diseño e Implementación de Red y HA (20%)

### Cambios implementados

Se migró de una arquitectura **Single-AZ** (1 subred pública, 1 zona) a una arquitectura **Multi-AZ** con subredes diferenciadas.

### Arquitectura de red actual

```
VPC: 10.1.0.0/16
│
├── Subredes PÚBLICAS (acceso desde Internet)
│   ├── 10.1.1.0/24  →  us-east-1a
│   └── 10.1.2.0/24  →  us-east-1b
│
├── Subredes PRIVADAS (solo tráfico interno / NAT saliente)
│   ├── 10.1.11.0/24 →  us-east-1a
│   └── 10.1.12.0/24 →  us-east-1b
│
├── Internet Gateway   →  tráfico entrante a subredes públicas
├── NAT Gateway        →  tráfico saliente desde subredes privadas
└── Route Tables       →  diferenciadas (pública / privada)
```

### Extracto de código – `main.tf`

```hcl
module "redes" {
  source = "github.com/olcduoc/terraform-aws-vpc-AUY1105-grupo-1?ref=v1.0.0"

  project_name = var.project_name
  vpc_cidr     = "10.1.0.0/16"

  # Multi-AZ: 2 subredes públicas en 2 zonas
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]

  # Subredes privadas en 2 zonas
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]

  # NAT Gateway para tráfico saliente desde subredes privadas
  enable_nat_gateway = true

  ssh_allowed_cidr = var.ssh_allowed_cidr
}
```

### Justificación frente a rúbrica

> **Competente/Excelente (80–100%):** *"La arquitectura contempla múltiples zonas de disponibilidad con subredes públicas y privadas correctamente segmentadas."*

La implementación incluye exactamente lo solicitado: 2 AZs, subredes públicas, subredes privadas, NAT Gateway y tablas de ruteo diferenciadas.

---

## Criterio 2 – Modularización y Calidad del Código (20%)

### Estado: Sin cambios requeridos ✅

La arquitectura modular ya estaba implementada desde EVA2. Se mantiene como está.

### Estructura de módulos

```
AUY1105-GRUPO-Nro1/ (repositorio principal)
├── main.tf        → orquesta módulos redes y computo
├── variables.tf   → variables externalizadas, sin credenciales hardcoded
├── outputs.tf     → outputs consolidados de ambos módulos
└── versions.tf    → provider AWS y versión Terraform fijados

Módulos externos:
  olcduoc/terraform-aws-vpc-AUY1105-grupo-1  → VPC, subredes, IGW, NAT, SG
  olcduoc/terraform-aws-ec2-AUY1105-grupo-1  → AMI, Key Pair, EC2, disco
```

### Buenas prácticas aplicadas

- Variables externalizadas en `variables.tf`, ninguna credencial en código.
- Outputs explícitos documentados con `description`.
- Versión del provider fijada (`~> 5.0`) y versión de Terraform mínima (`>= 1.5.0`).
- `sensitive = true` en la variable `public_key`.

---

## Criterio 3 – Gobernanza de Estado (15%)

### Cambio: de estado local a backend remoto S3 + DynamoDB

#### Paso 1: Bootstrap del backend (`bootstrap_backend.tf`)

Se crea primero el bucket S3 y la tabla DynamoDB con estado local:

```hcl
resource "aws_s3_bucket" "tfstate" {
  bucket        = "auy1105-grupo1-tfstate"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "auy1105-grupo1-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID" type = "S" }
}
```

#### Paso 2: Configuración del backend en `versions.tf`

```hcl
backend "s3" {
  bucket         = "auy1105-grupo1-tfstate"
  key            = "main/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "auy1105-grupo1-tfstate-lock"
}
```

#### Paso 3: Migración del estado local al remoto

```bash
terraform init -migrate-state
# Terraform detecta el estado local y pregunta si migrar → "yes"
```

#### Tabla de propiedades del backend

| Propiedad        | Valor                               | Propósito |
|------------------|-------------------------------------|-----------|
| Bucket S3        | `auy1105-grupo1-tfstate`            | Almacenar tfstate |
| Key              | `main/terraform.tfstate`            | Ruta dentro del bucket |
| Cifrado          | AES-256 (SSE-S3)                    | Proteger datos sensibles |
| Versionado S3    | Enabled                             | Recuperar estados anteriores |
| Tabla DynamoDB   | `auy1105-grupo1-tfstate-lock`       | Evitar apply concurrente |
| Acceso público   | Bloqueado (todas las opciones)      | Seguridad del estado |

### Justificación frente a rúbrica

> **Competente/Excelente (80–100%):** *"El estado se almacena de forma remota con control de versiones y bloqueo de concurrencia configurado."*

---

## Criterio 4 – Pipeline CI/CD y Automatización (15%)

### Flujo del pipeline

```
Pull Request → main
       │
       ▼
┌─────────────────────────────────────┐
│  JOB 1: validate-and-security       │
│  ┌─────────────────────────────┐    │
│  │ 1. terraform fmt -check     │    │
│  │ 2. terraform validate       │    │
│  │ 3. tflint                   │    │
│  │ 4. checkov (soft_fail=true) │    │
│  │ 5. terraform plan           │    │
│  │ 6. OPA – No SSH público     │    │
│  │ 7. OPA – Solo t2.micro      │    │
│  │ 8. Generar evidencia .md    │    │
│  │ 9. Comentar en PR           │    │
│  │ 10. Upload artefactos       │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
       │ (solo en push a main)
       ▼
┌─────────────────────────────────────┐
│  JOB 2: terraform-apply             │
│  ┌─────────────────────────────┐    │
│  │ 1. terraform init (S3)      │    │
│  │ 2. terraform apply          │    │
│  │ 3. Capturar outputs         │    │
│  │ 4. Generar evidencia apply  │    │
│  │ 5. Upload artefactos apply  │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### Herramientas del pipeline

| Herramienta | Versión / Acción | Propósito |
|-------------|-----------------|-----------|
| Terraform | `>= 1.5.0` | Validar, planificar y aplicar |
| TFLint | `terraform-linters/setup-tflint@v4` | Análisis estático |
| Checkov | `bridgecrewio/checkov-action@v12` | Seguridad IaC |
| OPA | `open-policy-agent/setup-opa@v2` | Políticas personalizadas |
| GitHub Actions | `actions/upload-artifact@v4` | Artefactos de evidencia |

### Secrets requeridos en GitHub

| Secret | Uso |
|--------|-----|
| `AWS_ACCESS_KEY_ID` | Autenticación AWS |
| `AWS_SECRET_ACCESS_KEY` | Autenticación AWS |
| `AWS_SESSION_TOKEN` | Autenticación AWS (Lab Academy) |
| `TF_VAR_PUBLIC_KEY` | Clave pública SSH para EC2 |

### Evidencias generadas automáticamente

El pipeline genera dos artefactos descargables en cada ejecución:

- `evidencia-pipeline-{run_number}/evidencia_pipeline.md` → resultado de validación y seguridad
- `evidencia-apply-{run_number}/evidencia_apply.md` → resultado del despliegue y outputs

Además, en cada **Pull Request** se publica automáticamente el informe como comentario.

---

## Criterio 5 – Versionado Semántico de Módulos (10%)

### Cambio: de commit hash a tag semántico

#### Antes (EVA2) ❌

```hcl
source = "github.com/olcduoc/terraform-aws-vpc-AUY1105-grupo-1?ref=9ff22fc7badf7e44230ca94e854834b3ad5fa16f"
source = "github.com/olcduoc/terraform-aws-ec2-AUY1105-grupo-1?ref=8ee259e5b942b04cdb5892828a996de24b29e721"
```

#### Después (EVA3) ✅

```hcl
source = "github.com/olcduoc/terraform-aws-vpc-AUY1105-grupo-1?ref=v1.0.0"
source = "github.com/olcduoc/terraform-aws-ec2-AUY1105-grupo-1?ref=v1.0.0"
```

### Pasos para crear los tags en los repos de módulos

```bash
# En el repo terraform-aws-vpc-AUY1105-grupo-1
git tag -a v1.0.0 -m "release: versión inicial estable del módulo VPC"
git push origin v1.0.0

# En el repo terraform-aws-ec2-AUY1105-grupo-1
git tag -a v1.0.0 -m "release: versión inicial estable del módulo EC2"
git push origin v1.0.0
```

### Tabla de versionado semántico

| Módulo | Tag | MAJOR | MINOR | PATCH | Significado |
|--------|-----|-------|-------|-------|-------------|
| redes  | `v1.0.0` | 1 | 0 | 0 | Primera versión estable |
| computo | `v1.0.0` | 1 | 0 | 0 | Primera versión estable |

### Reglas de versionado aplicadas

| Cambio | Versión | Ejemplo |
|--------|---------|---------|
| Cambio incompatible (nueva variable requerida) | MAJOR | `v2.0.0` |
| Nueva funcionalidad compatible (variable opcional) | MINOR | `v1.1.0` |
| Corrección de bug sin cambio de interfaz | PATCH | `v1.0.1` |

### Justificación frente a rúbrica

> **Competente/Excelente (80–100%):** *"Aplica versionado semántico con tags explícitos en los módulos y explica el impacto de los cambios de versión."*

---

## Políticas OPA – Referencia

### `terraform_ssh_check.rego` – No SSH público

```rego
package terraform.ssh

violation contains msg if {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("VIOLACION: Security Group '%v' expone SSH (Puerto 22) a 0.0.0.0/0.", [sg.address])
}
```

### `terraform_ec2_check.rego` – Solo t2.micro

```rego
package terraform.ec2

violation contains msg if {
  ec2 := input.resource_changes[_]
  ec2.type == "aws_instance"
  ec2.change.after.instance_type != "t2.micro"
  msg := sprintf("VIOLACION: Instancia EC2 '%v' usa tipo '%v'. Solo se permite 't2.micro'.", [ec2.address, ec2.change.after.instance_type])
}
```

---

## Instrucciones de Reproducción

```bash
# 1. Clonar el repositorio
git clone https://github.com/olcduoc/AUY1105-GRUPO-Nro1.git
cd AUY1105-GRUPO-Nro1

# 2. (Primera vez) Crear el backend S3 + DynamoDB
#    Asegurarse de que bootstrap_backend.tf esté en el directorio
terraform init          # usa estado local
terraform apply         # crea bucket S3 y tabla DynamoDB

# 3. Migrar el estado local al backend remoto
#    (descomentar el bloque backend "s3" en versions.tf primero)
terraform init -migrate-state

# 4. Eliminar o mover bootstrap_backend.tf fuera del directorio
#    (ya no es necesario; el bucket existe)

# 5. Verificar el plan con la nueva arquitectura
terraform plan -var="public_key=TU_CLAVE_PUBLICA"

# 6. Los cambios se despliegan automáticamente vía pipeline
#    al hacer merge de un PR hacia main
```

---

## Historial de Commits Relevantes

```
e271ddd  ci: agregar job terraform apply automatico en merge a main
b137c8c  Merge pull request #1 from olcduoc/feat/update-workflow-eva2
1dea0f8  fix: reemplazar tag por commit hash en source de módulos CKV_TF_1
cab59b2  ci: actualizar workflow para arquitectura modular EVA2
07889e8  fix: apuntar módulos a repositorio olcduoc
3c1635b  feat: migración a arquitectura modular EVA2 v2.0.0
```

---

*Documento generado para EFT126 – Infraestructura como Código II – Duoc UC 2026*
