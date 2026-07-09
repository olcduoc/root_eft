# root_eft

> **Evaluación Final Transversal (EFT126) — Infraestructura como Código II**
> Duoc UC · V Semestre 2026 · Docente: Camilo Jerez
> Entrega individual — Oscar Leiva

[![Pipeline DevSecOps](https://github.com/olcduoc/root_eft/actions/workflows/root_eft.yml/badge.svg)](https://github.com/olcduoc/root_eft/actions)
![Terraform](https://img.shields.io/badge/Terraform-≥1.5.0-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-us--east--1-FF9900?logo=amazon-aws)
![State](https://img.shields.io/badge/State-S3%20%2B%20DynamoDB-4FC3F7)
![Módulo VPC](https://img.shields.io/badge/módulo%20vpc__eft-v2.0.0-2E7D32)
![Módulo EC2](https://img.shields.io/badge/módulo%20ec2__eft-v1.0.0-1565C0)

---

## Descripción

Repositorio orquestador de la infraestructura AWS del proyecto individual **EFT-OscarLeiva**.
Aprovisiona una arquitectura de red **Multi-AZ** de alta disponibilidad consumiendo dos módulos
de Terraform independientes versionados semánticamente, con estado remoto cifrado en S3,
bloqueo de concurrencia en DynamoDB y un pipeline DevSecOps completo en GitHub Actions.

### Repositorios del proyecto

| Repositorio | Rol | Versión |
|---|---|---|
| **root_eft** ← *este repo* | Orquestador principal | — |
| [vpc_eft](https://github.com/olcduoc/vpc_eft) | Módulo de red | `v2.0.0` |
| [ec2_eft](https://github.com/olcduoc/ec2_eft) | Módulo de cómputo | `v1.0.0` |
| [terraform-aws-backend-EFT](https://github.com/olcduoc/terraform-aws-backend-EFT) | Gestión del backend S3+DynamoDB | estado local |

---

## Arquitectura desplegada

```
AWS us-east-1  ·  Cuenta: 339712721078
│
└── VPC: 10.1.0.0/16  (vpc-0dbadcc16e2c40c38)
    │
    ├── us-east-1a
    │   ├── subnet-public-1   10.1.1.0/24   → Internet Gateway
    │   └── subnet-private-1  10.1.11.0/24  → NAT Gateway
    │
    ├── us-east-1b
    │   ├── subnet-public-2   10.1.2.0/24   → Internet Gateway
    │   └── subnet-private-2  10.1.12.0/24  → NAT Gateway
    │
    ├── Internet Gateway  (igw-03a40e18371d454a2)
    ├── NAT Gateway       (nat-0c8520a60872f1bda)  ← subred pública us-east-1a
    ├── Route Table pública   → IGW
    ├── Route Table privada   → NAT Gateway
    ├── Security Group        (sg-0f19a13d859c659b2) → SSH/22 restringido a IP autorizada (/32)
    └── EC2 t2.micro          (i-07706b1c46498d116)  IP pública: 54.157.26.182
```

**Recursos totales desplegados:** 17 · **Apply:** 17 added, 0 changed, 0 destroyed

---

## Estructura del repositorio

```
root_eft/
├── .github/
│   └── workflows/
│       └── root_eft.yml                # Pipeline DevSecOps
├── main.tf                             # Módulos redes + computo
├── versions.tf                         # Backend S3 + providers
├── variables.tf                        # Variables de entrada
├── outputs.tf                          # Outputs de infraestructura
├── install.sh                          # User-data script para EC2
├── terraform_ssh_check.rego            # Política OPA: SSH no abierto a 0.0.0.0/0
├── terraform_ec2_check.rego            # Política OPA: tipo de instancia permitido
├── CHANGELOG.md                        # Historial de cambios por versión
└── README.md                           # Este archivo
```

---

## Configuración Terraform

### `versions.tf` — Backend remoto S3 + DynamoDB

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "eft-oleivac-tfstate"
    key            = "main/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "eft-oleivac-tfstate-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### `main.tf` — Módulos con versionado semántico

```hcl
module "redes" {
  source = "github.com/olcduoc/vpc_eft?ref=v2.0.0"

  project_name         = var.project_name
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
  enable_nat_gateway   = true
  ssh_allowed_cidr     = var.ssh_allowed_cidr
}

module "computo" {
  source = "github.com/olcduoc/ec2_eft?ref=v1.0.0"

  project_name      = var.project_name
  subnet_id         = module.redes.subnet_ids[0]
  security_group_id = module.redes.security_group_id
  public_key        = var.public_key
  instance_type     = "t2.micro"
  volume_size       = 8
  volume_type       = "gp3"
  user_data_script  = "${path.module}/install.sh"
}
```

### `variables.tf`

```hcl
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
  default     = "EFT-OscarLeiva"
}
```

### `outputs.tf`

```hcl
output "instance_id"        { value = module.computo.instance_id }
output "instance_ip"        { value = module.computo.instance_ip }
output "vpc_id"             { value = module.redes.vpc_id }
output "security_group_id"  { value = module.redes.security_group_id }
output "public_subnet_ids"  { value = module.redes.public_subnet_ids }
output "private_subnet_ids" { value = module.redes.private_subnet_ids }
output "nat_gateway_id"     { value = module.redes.nat_gateway_id }
```

---

## Pipeline CI/CD

El archivo `.github/workflows/root_eft.yml` implementa un pipeline DevSecOps
con dos jobs secuenciales:

```
push / PR                                    merge a main
    │                                              │
    ▼                                              ▼
┌──────────────────────┐              ┌──────────────────────┐
│  Validación y        │    éxito     │  Despliegue          │
│  Seguridad            │─────────────►│  (Terraform Apply)   │
│                      │              │                      │
│  • terraform fmt     │              │  • terraform init    │
│  • terraform validate│              │  • terraform apply   │
│  • Checkov           │              │    -auto-approve     │
│  • OPA / Rego        │              │                      │
└──────────────────────┘              └──────────────────────┘
```

### Secrets requeridos en GitHub

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key de AWS Academy (rotan cada ~4h) |
| `AWS_SECRET_ACCESS_KEY` | Secret key de AWS Academy |
| `AWS_SESSION_TOKEN` | Session token de AWS Academy |
| `TF_VAR_PUBLIC_KEY` | Clave pública SSH para la instancia EC2 |

> **Nota AWS Academy:** las credenciales rotan automáticamente. Actualizar los cuatro secrets
> desde el panel Vocareum antes de cada ejecución larga del pipeline.

### Políticas OPA incluidas

- **`terraform_ssh_check.rego`** — Valida que ningún Security Group permita SSH (`22/tcp`) desde `0.0.0.0/0`.
- **`terraform_ec2_check.rego`** — Valida que el tipo de instancia EC2 esté dentro de los tipos permitidos.

### Nota sobre Checkov (CKV_TF_1)

El análisis estático de Checkov reporta que los módulos `redes` y `computo` se referencian por
**tag semántico** (`?ref=v2.0.0`, `?ref=v1.0.0`) en lugar de por hash de commit fijo. Es una decisión
de diseño consciente: se priorizó la trazabilidad y legibilidad que aporta el versionado semántico.
El hallazgo queda documentado y no bloquea el despliegue.

---

## Versionado Semántico — Módulo VPC (`vpc_eft`)

El módulo de red evolucionó con tres versiones publicadas como tags de Git:

| Tag | Tipo | Cambios |
|---|---|---|
| `v0.1.0` | Initial | Primer borrador funcional, sin garantía de estabilidad |
| `v1.0.0` | STABLE | Interfaz de variables/outputs estabilizada, primera versión en producción |
| `v2.0.0` | **MAJOR** | Agrega `private_subnet_cidrs`, `enable_nat_gateway`, soporte Multi-AZ — **rompe compatibilidad con v1.x** |

El orquestador consume los módulos anclados a tags específicos (`?ref=v2.0.0`, `?ref=v1.0.0`) en lugar de
referencias a ramas, garantizando reproducibilidad del despliegue aunque los módulos sigan evolucionando.

---

## Gobernanza de estado — decisión de arquitectura

> ⚠️ **El bucket S3 y la tabla DynamoDB NO se gestionan desde este repositorio.**

Gestionar la infraestructura del backend en el mismo proyecto Terraform que la consume
genera una **dependencia circular**: el backend no puede almacenar su propio estado mientras
los recursos que lo forman dependen de ese estado para existir.

**Solución aplicada:** el backend se gestiona en el repositorio independiente
[terraform-aws-backend-EFT](https://github.com/olcduoc/terraform-aws-backend-EFT)
con estado local, separando completamente las responsabilidades.

### Recursos del backend (gestionados externamente)

| Recurso AWS | ID / Nombre |
|---|---|
| Bucket S3 | `eft-oleivac-tfstate` |
| Versionado | Habilitado |
| Cifrado | AES-256 (SSE-S3) |
| Acceso público | Bloqueado |
| Tabla DynamoDB | `eft-oleivac-tfstate-lock` |
| Clave de partición | `LockID` (String) |
| Modo de capacidad | PAY_PER_REQUEST (bajo demanda) |

---

## Despliegue

### Prerrequisitos

- Terraform `>= 1.5.0`
- AWS CLI configurado con credenciales válidas de AWS Academy
- Par de claves SSH disponible en `~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`
- Acceso de lectura a los repositorios de módulos en GitHub

### 1. Clonar el repositorio

```bash
git clone https://github.com/olcduoc/root_eft.git
cd root_eft
```

### 2. Verificar identidad AWS

```bash
aws sts get-caller-identity
```

### 3. Inicializar Terraform

```bash
terraform init
```

Terraform descarga automáticamente los módulos anclados a sus tags de Git:

```
Downloading git::https://github.com/olcduoc/vpc_eft.git?ref=v2.0.0 for redes...
Downloading git::https://github.com/olcduoc/ec2_eft.git?ref=v1.0.0 for computo...
Terraform has been successfully initialized!
```

### 4. Planificar

```bash
terraform plan -var="public_key=$(cat ~/.ssh/id_rsa.pub)"
```

**Resultado esperado:** `Plan: 17 to add, 0 to change, 0 to destroy.`

### 5. Aplicar

```bash
terraform apply -var="public_key=$(cat ~/.ssh/id_rsa.pub)" -auto-approve
```

**Outputs tras el apply:**

```
instance_id        = "i-07706b1c46498d116"
instance_ip        = "54.157.26.182"
nat_gateway_id     = "nat-0c8520a60872f1bda"
private_subnet_ids = ["subnet-0aa8d874cad0cc362", "subnet-0a10451afb366a5be"]
public_subnet_ids  = ["subnet-012302d5b387cb63f", "subnet-05601008e00a0728f"]
security_group_id  = "sg-0f19a13d859c659b2"
vpc_id             = "vpc-0dbadcc16e2c40c38"
```

### 6. Verificar conectividad SSH

```bash
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw instance_ip)
```

---

## Destrucción

> ⚠️ Ejecutar **siempre** al finalizar la sesión del laboratorio AWS Academy
> para no agotar los créditos disponibles.

```bash
terraform destroy -var="public_key=$(cat ~/.ssh/id_rsa.pub)" -auto-approve
```

**Resultado esperado:** `Destroy complete! Resources: 17 destroyed.`

> El bucket S3 (`eft-oleivac-tfstate`) y la tabla DynamoDB (`eft-oleivac-tfstate-lock`)
> **no se destruyen** con este comando — se gestionan desde el proyecto de backend independiente
> y se reutilizan entre sesiones.

---

## Troubleshooting

### `AccessDeniedException: dynamodb:PutItem ... voc-cancel-cred`

Las credenciales de AWS Academy expiraron. La política `voc-cancel-cred` bloquea el acceso
cuando el laboratorio está por expirar.

```bash
# Renovar desde Vocareum y actualizar ~/.aws/credentials
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=IQoJb3...
EOF

aws sts get-caller-identity  # verificar
```

Actualizar también los cuatro GitHub Secrets del repositorio.

### `Error: Module not installed`

```bash
terraform init -upgrade  # descarga los módulos por tag antes de planificar
```

### `Plan: X to add, 0 to change, 5 to destroy` (destrucciones inesperadas del backend)

El estado del orquestador contiene referencias a los recursos del backend. Removerlas sin destruir en AWS:

```bash
terraform state rm aws_s3_bucket.tfstate
terraform state rm aws_s3_bucket_versioning.tfstate
terraform state rm aws_s3_bucket_server_side_encryption_configuration.tfstate
terraform state rm aws_s3_bucket_public_access_block.tfstate
terraform state rm aws_dynamodb_table.tfstate_lock
```

### `Warning: Deprecated Parameter` — `dynamodb_table`

Con Terraform >= 1.10 el parámetro `dynamodb_table` del bloque `backend "s3"` está deprecado en
favor de `use_lockfile`. Este proyecto se mantiene con `dynamodb_table` de forma deliberada por
compatibilidad con Terraform 1.5, versión mínima requerida (`required_version = ">= 1.5.0"`).

### `! [rejected] main -> main (fetch first)`

```bash
git pull origin main --rebase
git push origin <rama>
```

### Lock de DynamoDB activo tras fallo de credenciales

```bash
# Obtener el Lock ID del mensaje de error y forzar su liberación
terraform force-unlock <LOCK-ID>
```

---

## Autoría

| Integrante | GitHub | Rol |
|---|---|---|
| Oscar Leiva | `olcduoc` | Orquestador, módulos, backend, pipeline CI/CD, documentación |

**Cuenta AWS Academy:** `339712721078` · Región: `us-east-1`
**Docente:** Camilo Jerez · **Asignatura:** AUY1105 — Infraestructura como Código II
**Institución:** Duoc UC · **Semestre:** V — 2026

---

## Licencia

Proyecto académico — Duoc UC 2026. No usar en producción sin adaptación.
