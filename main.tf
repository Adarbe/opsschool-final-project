provider "aws" {
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  region = "us-east-1"
}


data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
      name = "name"
      values = [
        "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
    owners = ["099720109477"]# Canonical
}


data "aws_availability_zones" "available" {}


data "template_file" "node_exporter" {
  template = file("${path.module}/templates/node_exporter.sh.tpl")

  vars = {
    node_exporter_version = "0.18.0"
  }
}



module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "final-project"
  cidr = "10.0.0.0/16"
  enable_dns_hostnames = true

  azs                 = data.aws_availability_zones.available.names
  private_subnets     = var.vpc_private_subnets
  public_subnets      = var.vpc_public_subnets
#  database_subnets    = var.vpc_database_subnets
#  create_database_subnet_group = false
  enable_nat_gateway = false
  one_nat_gateway_per_az = false
  single_nat_gateway = false
  tags = {
    Name = "final_project"
  }
  private_subnet_tags = {
    Name = "pri_sub"
  }
  public_subnet_tags = {
    Name = "pub_sub"
  }
}




