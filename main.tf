# main.tf  —  Repositorio Principal root_eft (Oscar Leiva)
# Arquitectura Multi-AZ con subredes públicas y privadas (EFT)

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
