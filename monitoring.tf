
######### Monitoring Security Group ##############
resource "aws_security_group" "final_monitoring" {
  name        = "final_monitoring"
  vpc_id = module.vpc.vpc_id
  description = "Security group for monitoring server"
  
  # Allow ICMP from control host IP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.my_ip]
  }
  # Allow all SSH External
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.my_ip]
  }
  # Allow all traffic to HTTP port 3000
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = [var.my_ip]
  }
  # Allow all traffic to HTTP port 9090
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "TCP"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Node exporter"
  }
  
  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Consul exporter"
  }
  ingress {
    from_port   = 9114
    to_port     = 9114
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Elasticsearch exporter"
  }

  ingress {
    from_port   = 9118
    to_port     = 9118
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Elasticsearch exporter"
  }

  ingress {
    from_port   = 9563
    to_port     = 9563
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Elasticsearch exporter"
  }

    ingress {
    from_port   = 9649
    to_port     = 9649
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Logstash Exporter"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
   ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow consul UI access from the world"
  }
  # Allow ICMP from control host IP
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow all outside security group"
  }
  tags = {
    Name = "Final-Monitor-SG"
  }
}


data "template_file" "consul_monitoring" {
  template = file("${path.module}/templates/consul.sh.tpl")
  
  vars = {
    prometheus_dir = var.prometheus_dir
    config = <<EOF
       "node_name": "monitoring-server",
       "enable_script_checks": true,
       "server": false
      EOF
  }
}

data "template_file" "monitoring_sh_tpl" {
  template = file("${path.module}/monitoring/templates/monitoring.sh.tpl")

  vars = {
    HOSTNAME = "Grafana-monitoring"
  }
}

data "template_file" "monitoring_sh" {
  template = file("${path.module}/monitoring/monitoring_server.sh")
}



#Create the user-data for the monitoring server

data "template_cloudinit_config" "monitoring_settings" {
  part {
    content = data.template_file.consul_monitoring.rendered
  }
  part {
    content = data.template_file.monitoring_sh_tpl.rendered
  }
  part {
    content = data.template_file.monitoring_sh.rendered
  }
  part {
    content = data.template_file.node_exporter.rendered
  }
}


# Allocate the EC2 monitoring instance
resource "aws_instance" "monitor" {
  count = var.monitor_servers
  ami = data.aws_ami.ubuntu.id
  instance_type = var.monitor_instance_type
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = ["${aws_security_group.final_monitoring.id}","${aws_security_group.final_consul.id}"]
  key_name = aws_key_pair.servers_key.key_name
  associate_public_ip_address = true
  tags = {
    Owner = var.owner
    Name  = "Monitor-${count.index+1}"
    consul_server = "false"
    HTTP = "80"
  }
  connection {
    type = "ssh"
    host = aws_instance.monitor[count.index].public_ip
    private_key = tls_private_key.servers_key.private_key_pem
    user = "ubuntu"
  }
  provisioner "file" {
    source      = "monitoring"
    destination = "/home/ubuntu/"
  }

  
  user_data = data.template_cloudinit_config.monitoring_settings.rendered
}