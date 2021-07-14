provider "aws" {
  region = "eu-west-1"
}

locals {
  name   = "my-vpc"
  region = "eu-west-1"

  tags = {
    Owner       = "vmn"
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"


  azs             = ["eu-west-1a"] #, "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24"] #, "10.0.2.0/24", "10.0.3.0/24"]
  #public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = merge (local.tags, {Type = "Network"})

}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "example"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = merge (local.tags, {Type = "SG"})
}

module "ec2_cluster" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "${local.tags.Owner}-${local.tags.Environment}-ec2"
  instance_count         = 1

  ami                    = "ami-058b1b7fe545997ae"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  monitoring             = false
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = module.vpc.private_subnets[0] #"subnet-eddcdzz4"

  tags = merge (local.tags, {Type = "Linux"})
}