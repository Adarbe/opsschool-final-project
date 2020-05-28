locals {
  jenkins_default_name = "jenkins"
  jenkins_home = "/home/ubuntu/jenkins_home"
  jenkins_home_mount = "${local.jenkins_home}:/var/jenkins_home"
  docker_sock_mount = "/var/run/docker.sock:/var/run/docker.sock"
  java_opts = "JAVA_OPTS='-Djenkins.install.runSetupWizard=false'" 
}

######### Jenkins Security Group ##############
resource "aws_security_group" "jenkins-final" {
  name = "jenkins-final"
  vpc_id = module.vpc.vpc_id


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all inside security group"
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
    description = "Allow Jenkins inbound traffic"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 2375
    to_port = 2375
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
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = [var.my_ip]
    description     = "Allow all outside security group"
  }
  tags = {
    Name = "Final-Jenkins-SG"
  }  
}


data "template_file" "jenkins_master_sh" {
  template = file("${path.module}/jenkins/jenkins_master.sh.tpl")
}

data "template_file" "consul_jenkins" {
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
      node_exporter_version = var.node_exporter_version
      prometheus_dir = var.prometheus_dir
      config = <<EOF
       "node_name": "jenkins-server-1",
       "enable_script_checks": true,
       "server": false
      EOF
  }
}


# Create the user-data for the jenkins master
data "template_cloudinit_config" "jenkins_master_settings" {
  part {
    content = data.template_file.consul_jenkins.rendered
  }
  part {
    content = data.template_file.jenkins_master_sh.rendered
  }
  part {
    content = data.template_file.node_exporter.rendered
  }
}


resource "aws_instance" "jenkins_master" {
#######################################################
# description = "create EC2 machine for jenkins master"
#######################################################
  ami = "ami-024582e76075564db"
  instance_type = "t2.micro"
  key_name = aws_key_pair.servers_key.key_name
  tags = {
    Name = "Jenkins_Master-1"
    Labels = "linux"
  }
  vpc_security_group_ids =["${aws_security_group.jenkins-final.id}","${aws_security_group.final_consul.id}", "${aws_security_group.final_monitoring.id}"]
  iam_instance_profile   = aws_iam_instance_profile.opsschool-deploy-app.name
  subnet_id = module.vpc.public_subnets[1]
  connection {
    type = "ssh"
    host = aws_instance.jenkins_master.public_ip
    private_key = tls_private_key.servers_key.private_key_pem
    user = "ubuntu"
  }
 
  provisioner "file" {
    source = "jenkins/Dockerfile"
    destination = "/home/ubuntu/Dockerfile" 
  }
  provisioner "file" {
    source = "jenkins/plugins.txt"
    destination = "/home/ubuntu/plugins.txt" 
  }
  user_data = data.template_cloudinit_config.jenkins_master_settings.rendered
}




################################################################################



data "template_file" "consul_jenkins_slave" {
  template = file("${path.module}/templates/consul-agent-linux.sh.tpl")

  vars = {
    node_exporter_version = var.node_exporter_version
    config = <<EOF
       "node_name": "jenkins_slave-1",
       "enable_script_checks": true,
       "server": false
      EOF
    }
  }

data "template_file" "jenkins_slave_sh" {
  template = file("${path.module}/templates/jenkins_slave.sh.tpl")
}

#Create the user-data for the jenkins slave
data "template_cloudinit_config" "consul_jenkins_slave_settings" {
  count =  1
  part {
    content = element(data.template_file.consul_jenkins_slave.*.rendered, count.index)
  }
  part {
    content = element(data.template_file.jenkins_slave_sh.*.rendered, count.index)
  }
  part {
    content = element(data.template_file.node_exporter.*.rendered, count.index)
  }
}

resource "aws_instance" "jenkins_slave" {
#########################################################
# description = "create 3 EC2 machines for jenkins slave"
#########################################################
  count = 1
  ami = "ami-00068cd7555f543d5"
  instance_type = "t2.micro"
  key_name = aws_key_pair.servers_key.key_name
  associate_public_ip_address = true
  subnet_id = module.vpc.public_subnets[2]
  iam_instance_profile   = aws_iam_instance_profile.opsschool-deploy-app.name
  vpc_security_group_ids =["${aws_security_group.jenkins-final.id}","${aws_security_group.final_consul.id}","${aws_security_group.final_monitoring.id}"]
  tags = {
    Name = "jenkins_slave-${count.index+1}"
    Labels = "linux"
  }
  connection {
    type = "ssh"
    host = aws_instance.jenkins_slave[count.index].public_ip
    private_key = tls_private_key.servers_key.private_key_pem
    user = "ec2-user"
  }
  user_data = element(data.template_cloudinit_config.consul_jenkins_slave_settings.*.rendered, count.index)
}
