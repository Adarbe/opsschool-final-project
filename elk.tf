# ######### ELK Security Group ##############

# resource "aws_security_group" "final_elk" {
#   name = "allow_elk"
#   description = "All all elasticsearch traffic"
#   vpc_id = module.vpc.vpc_id
  
#   # elasticsearch port
#   ingress {
#     from_port   = 9200
#     to_port     = 9200
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip]
#   }
#   # logstash port
#   ingress {
#     from_port   = 5043
#     to_port     = 5044
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip]
#   }
#   # kibana ports
#   ingress {
#     from_port   = 5601
#     to_port     = 5601
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip]
#   }
#   # ssh
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip]
#   }
#   # outbound
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "Final_ELK-SG"
#   }
# }

# #####################################


# data "template_file" "elk_script" {
#   template = file("${path.module}/elk/templates/elasticsearch.sh")
# }



# data "template_file" "consul_elk_tpl" {
#   template = file("${path.module}/templates/consul.sh.tpl")
#     vars = {
#     consul_version = var.consul_version
#     node_exporter_version = var.node_exporter_version
#     prometheus_dir = var.prometheus_dir
#     config = <<EOF
#        "node_name": "elk",
#        "enable_script_checks": true,
#        "server": false
#       EOF
#     }
# }


# data "template_cloudinit_config" "elk_config" {
#   part {
#     content = data.template_file.elk_script.rendered
#   }
#   part {
#     content = data.template_file.consul_elk_tpl.rendered
#   }
# }


# resource "aws_instance" "elk" {
#   ami = "ami-07d0cf3af28718ef8"
#   instance_type = "t2.micro"
#   iam_instance_profile   = aws_iam_instance_profile.consul-join.name
#   key_name = aws_key_pair.servers_key.key_name
#   tags = {
#     Name = "elk-final"
#     Labels = "linux"
#   }
#   vpc_security_group_ids = ["${aws_security_group.final_elk.id}","${aws_security_group.final_consul.id}","${aws_security_group.final_monitoring.id}"]
#   subnet_id = module.vpc.public_subnets[2]
#   connection {
#     type = "ssh"
#     host = "${aws_instance.elk.public_ip}"
#     private_key = "${tls_private_key.servers_key.private_key_pem}"
#     user = "ubuntu"
#   }
#   provisioner "file" {
#     content      = "network.bind_host: 0.0.0.0"
#     destination   = "/tmp/elasticsearch.yml"
    
#     connection {
#       type = "ssh"
#       private_key = "${tls_private_key.servers_key.private_key_pem}"
#       user = "ubuntu"
#     }
#   }
#   provisioner "file" {
#     content       = "server.host: 0.0.0.0"
#     destination   = "/tmp/kibana.yml"
    
#     connection {
#       type = "ssh"
#       private_key = "${tls_private_key.servers_key.private_key_pem}"
#       user = "ubuntu"
#     }
#   }
#   provisioner "file" {
#     content       = "http.host: 0.0.0.0"
#     destination   = "/tmp/logstash.yml"
    
#     connection {
#       type = "ssh"
#       private_key = "${tls_private_key.servers_key.private_key_pem}"
#       user = "ubuntu"
#     }
#   }
#   provisioner "file" {
#     source        = "${path.module}/elk/templates/filebeat.yml"
#     destination   = "/tmp/filebeat.yml"
    
#     connection {
#       type = "ssh"
#       private_key = "${tls_private_key.servers_key.private_key_pem}"
#       user = "ubuntu"
#     }
#   }
#   provisioner "file" {
#     source        = "${path.module}/elk/templates/beats.conf"
#     destination   = "/tmp/beats.conf"

#     connection {
#       type = "ssh"
#       private_key = "${tls_private_key.servers_key.private_key_pem}"
#       user = "ubuntu"
#     }
#   }


#   user_data = data.template_cloudinit_config.elk_config.rendered
# }


# resource "aws_eip" "ip" {
#   instance = "${aws_instance.elk.id}"
# }