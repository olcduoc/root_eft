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
