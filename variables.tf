############ General ######################

variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "aws_region" {
  default = "us-east-1"
}

variable "my_ip"{
  default = "79.180.99.239/32"
  description = "my ip address"
}

############ VPC ######################
variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
  default = ""
}
variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = ""
}

variable "vpc_azs" {
  description = "Availability zones for VPC"
  type        = list(string)
  default     = []
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.30.0/24", "10.0.40.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type    = bool
  default = true
}

############### Monitoring ###############

variable "monitor_instance_type" {
  default = "t2.micro"
}
variable "monitor_servers" {
  default = 1
}
variable "owner" {
  default = "Monitoring"
}
variable "default_keypair_name" {
  description = "Name of the KeyPair used for all nodes"
  default     = "servers_key"
}


############### Consul ###############
variable "region" {
  description = "AWS region for VMs"
  default = "us-east-1"
}
variable "path" {
    type = string
    default = "/Users/adarb/projects/final-copy/" 
}
variable "consul_servers" {
  description = "The number of consul servers."
  default = 3
}
variable "consul_version" {
  description = "The version of Consul to install (server and client)."
  default     = "1.4.0"
}
variable "key_name" {
  description = "name of ssh key to attach to hosts"
  default = "servers_keypair_name"
}

variable "prometheus_dir" {
  description = "directory for prometheus binaries"
  default = "/opt/prometheus"
}

variable "prometheus_conf_dir" {
  description = "directory for prometheus configuration"
  default = "/etc/prometheus"
}

variable "node_exporter_version" {
  description = "Node Exporter version"
  default = "0.18.1"
}



############ ### ######################

