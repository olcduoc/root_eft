# Informe de Evidencias EFT126 – root_eft (Entrega Individual)

**Fecha:** 2026-07-09
**Estudiante:** Oscar Leiva
**Docente:** Camilo Jerez
**Institución:** Duoc UC – 2026
**Repositorio orquestador:** https://github.com/olcduoc/root_eft
**Módulos:** [vpc_eft](https://github.com/olcduoc/vpc_eft) `v2.0.0` · [ec2_eft](https://github.com/olcduoc/ec2_eft) `v1.0.0`
**Backend:** [terraform-aws-backend-EFT](https://github.com/olcduoc/terraform-aws-backend-EFT)

---

## Resumen de Criterios y Estado

| # | Criterio de Rúbrica | Pond. | Estado |
|---|---------------------|-------|--------|
| 1 | Diseño e Implementación de Red y HA | 20% | ✅ Multi-AZ (2 AZs, subredes públicas/privadas, NAT GW) |
| 2 | Modularización y Calidad del Código | 20% | ✅ Módulos independientes con variables/outputs/README |
| 3 | Gobernanza de Estado | 15% | ✅ S3 (`eft-oleivac-tfstate`) + DynamoDB (`eft-oleivac-tfstate-lock`) |
| 4 | Pipeline CI/CD y Automatización | 15% | ✅ TFLint/Checkov/OPA + despliegue automático |
| 5 | Versionado Semántico de Módulos | 10% | ✅ Tags v0.1.0 → v1.0.0 → v2.0.0 |
| 6 | Presentación y Defensa Oral | 20% | ⏳ Pendiente |

---

## Criterio 1 – Diseño e Implementación de Red y HA (20%)

Arquitectura Multi-AZ (us-east-1a / us-east-1b): VPC `10.1.0.0/16`, 2 subredes públicas
(`10.1.1.0/24`, `10.1.2.0/24`) y 2 privadas (`10.1.11.0/24`, `10.1.12.0/24`), Internet Gateway,
NAT Gateway en subred pública, Route Tables diferenciadas, Security Group con SSH restringido
a IP específica (`186.10.98.147/32`).

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
```

## Criterio 2 – Modularización y Calidad del Código (20%)

Tres repositorios independientes: `vpc_eft`, `ec2_eft`, `terraform-aws-backend-EFT`, orquestados
desde `root_eft`. Cada módulo tiene `variables.tf`, `outputs.tf`, `versions.tf`, `README.md` con
ejemplo de uso/parámetros/dependencias, y `CHANGELOG.md`. Sin credenciales hardcodeadas
(`public_key` marcada `sensitive`, inyectada vía GitHub Secret `TF_VAR_PUBLIC_KEY`).

## Criterio 3 – Gobernanza de Estado (15%)

Backend gestionado en proyecto independiente (`terraform-aws-backend-EFT`, estado local
intencional) para evitar dependencia circular con el backend que `root_eft` consume:

```hcl
backend "s3" {
  bucket         = "eft-oleivac-tfstate"
  key            = "main/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "eft-oleivac-tfstate-lock"
}
```

Bucket con versionado + cifrado AES-256 + bloqueo de acceso público. Tabla DynamoDB
`PAY_PER_REQUEST` con `LockID` como clave de partición.

## Criterio 4 – Pipeline CI/CD y Automatización (15%)

Workflow `.github/workflows/root_eft.yml`, 2 jobs:
1. **Validación y Seguridad** (PR): `terraform fmt`, `validate`, TFLint, Checkov, `terraform plan`,
   políticas OPA/Rego (`terraform_ssh_check.rego`, `terraform_ec2_check.rego`).
2. **Despliegue** (push a `main`): `terraform apply -auto-approve`.

Hallazgo documentado de Checkov (CKV_TF_1 — módulos por tag en vez de hash): decisión de diseño
consciente, no bloquea el despliegue.

## Criterio 5 – Versionado Semántico (10%)

| Módulo | Tags | Última versión |
|---|---|---|
| vpc_eft | v0.1.0, v1.0.0, v2.0.0 | v2.0.0 (MAJOR: Multi-AZ, NAT GW, subredes privadas) |
| ec2_eft | v0.1.0, v1.0.0 | v1.0.0 (STABLE) |

`root_eft` consume ambos por `?ref=vX.Y.Z` explícito, garantizando reproducibilidad.

## Políticas OPA – Referencia

```rego
package terraform.ssh
violation contains msg if {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("VIOLACION: Security Group '%v' expone SSH a 0.0.0.0/0.", [sg.address])
}
```

## Instrucciones de Reproducción

```bash
git clone https://github.com/olcduoc/root_eft.git && cd root_eft
terraform init
terraform plan -var="public_key=$(cat ~/.ssh/id_rsa.pub)"
# El apply se ejecuta automáticamente vía pipeline al hacer merge a main
```

---

*Documento actualizado para la entrega individual EFT126 – AUY1105 – Duoc UC 2026*
