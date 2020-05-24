#!/usr/bin/env bash
set -e

tee /etc/profile.d/custom.lang.sh <<EOF >/dev/null  
## US English ##
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8
EOF

source /etc/profile.d/custom.lang.sh

yum update -y
yum install java-1.8.0 -y
yum install docker git -y
service docker start
usermod -aG docker ec2-user

yum install python-pip -y
pip install awscli
yum install git -y

ssh-keygen -q -t rsa -N '' -f /home/ec2-user/.ssh/id_rsa 
chmod 600 /home/ec2-user/.ssh/id_rsa
chmod 600 /home/ec2-user/.ssh/id_rsa.pub
cat /home/ec2-user/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys



### add jenkins service to consul
tee /etc/consul.d/jenkins-slave.json > /dev/null <<"EOF"
{
 "service": {
    "name": "jenkins-slave",
    "port": 22,
    "check": 
      {
        "id": "ssh",
        "name": "SSH on port 22",
        "tcp": "localhost:22",
        "interval": "10s",
        "timeout": "1s"
      }
    }
  }
}

EOF 

/usr/local/bin/consul reload


tee /etc/consul.d/node-exporter.json > /dev/null <<"EOF"
{
  "service":
  {"name": "node-exporter-jenkins-slave",
   "tags": ["node_exporter", "prometheus"],
   "port": 9100
  }
}
EOF

consul reload


tee /etc/consul.d/node-exporter.json > /dev/null <<"EOF"
{
  "service": {
    "name": "node-exporter-jenkins-slave",
    "tags": ["node_exporter","prometheus"],
    "port": 9100
}

EOF


systemctl daemon-reload
systemctl start node_exporter
systemctl status --no-pager node_exporter
systemctl enable node_exporter



### add jenkins service to consul
tee /etc/consul.d/jenkins-master.json > /dev/null <<"EOF"
{
 "service": {
    "name": "jenkins-slave",
    "port": 22,
    "check": {
      {
        "id": "tcp",
        "name": "TCP on port 22",
        "http": "localhost:22",
        "interval": "10s",
        "timeout": "1s"
      }
    }
  }
}
EOF

systemctl daemon-reload
systemctl enable consul.service
systemctl start consul.service