
provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}


locals {
  cluster_name = "opsSchool-eks-final-project"
}


# CIDR will be "My IP" \ all Ips from which you need to access the worker nodes
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
     "10.0.0.0/16",
     "77.138.249.64/32",
     "199.203.102.38/32",
     "207.232.13.77/32",
     "192.168.1.0/32"
    ]
  }
#   ingress { (consul)
#     from_port = 8500
#     to_port   = 8500
#     protocol  = "tcp"
#     security_groups
#     cidr_blocks = 
#   }
#    egress 0--0
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  #TODO Ssbnet id
  subnets = module.vpc.private_subnets

  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  # TODO Worker group 1
  # One Subnet
  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }

  ]

}