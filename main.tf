# ─────────────────────────────────────────────────────────────
# main.tf  –  Repositorio Principal AUY1105-GRUPO-Nro1
# Orquesta los módulos de redes y cómputo (EVA2)
# ─────────────────────────────────────────────────────────────

module "redes" {
  source = "github.com/olcduoc/terraform-aws-vpc-AUY1105-grupo-1?ref=v1.0.0"

  project_name        = var.project_name
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24"]
  availability_zones  = ["us-east-1a"]
  ssh_allowed_cidr    = var.ssh_allowed_cidr
}

module "computo" {
  source = "github.com/olcduoc/terraform-aws-ec2-AUY1105-grupo-1?ref=v1.0.0"

  project_name      = var.project_name
  subnet_id         = module.redes.subnet_ids[0]
  security_group_id = module.redes.security_group_id
  public_key        = var.public_key
  instance_type     = "t2.micro"
  volume_size       = 8
  volume_type       = "gp3"
  user_data_script  = "${path.module}/install.sh"
}
