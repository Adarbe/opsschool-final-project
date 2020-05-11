
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "final-project"
  cidr = "10.0.0.0/16"

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