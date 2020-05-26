######### Consul Security Group ##############
resource "aws_security_group" "final_consul" {
  name        = "final-consul"
  vpc_id = module.vpc.vpc_id
  description = "Allow ssh & consul inbound traffic"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all inside security group"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow ssh from the world"
  }
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow https from the world"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow http from the world"
  }
  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Consul exporter"
  }
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow consul UI access from the world"
  }
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow servers to handle incoming requests from other agents"
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow servers handle gossip in the LAN. Required by all agents"
  }
  
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = [var.my_ip]
    description = "Allow servers handle gossip in the LAN. Required by all agents"
  }
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow servers to gossip over the WAN to other servers"
  }
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = [var.my_ip]
    description = "Allow servers to gossip over the WAN to other servers"
  }
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow all agents to handle RPC from the CLI"
  }
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Resolve DNS queries"
  }
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = [var.my_ip]
    description = "Resolve DNS queries"
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow all outside security group"
  }
  tags = {
    Name = "Final-consul-SG"
  }
}



data "template_file" "consul_server_tpl" {
  count    = var.consul_servers
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
    consul_version = var.consul_version
    node_exporter_version = var.node_exporter_version
    prometheus_dir = var.prometheus_dir
    config = <<EOF
      "node_name": "consul-server-${count.index +1}",
      "server": true,
      "bootstrap_expect": 3,
      "ui": true,
      "client_addr": "0.0.0.0",
      "telemetry": {
        "prometheus_retention_time": "10m"
      }
  EOF
  }
}

data "template_file" "consul_node_exporter" {
  count    = var.consul_servers
  template = file("${path.module}/templates/consul_node_exporter.sh.tpl")
}

#Create the user-data for the consul server
data "template_cloudinit_config" "consul_server_settings" {
  count    = var.consul_servers
  part {
    content = element(data.template_file.consul_server_tpl.*.rendered, count.index)
  }
  part {
    content = element(data.template_file.consul_node_exporter.*.rendered, count.index)
  }
}


# Create the Consul cluster
resource "aws_instance" "consul_server" {
  count                  = var.consul_servers
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  subnet_id = module.vpc.public_subnets[count.index]
  ami                    = "ami-024582e76075564db"
  instance_type          = "t2.micro"
  key_name = aws_key_pair.servers_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = ["${aws_security_group.final_consul.id}", "${aws_security_group.final_monitoring.id}"]
  tags = {
    Name  = "consul-server-${count.index + 1}"
    consul_server = "true"
  }
  user_data = element(data.template_cloudinit_config.consul_server_settings.*.rendered, count.index)
}