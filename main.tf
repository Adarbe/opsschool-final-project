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
