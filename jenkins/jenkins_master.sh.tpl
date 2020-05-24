#!/usr/bin/env bash
set -e

apt-get update -y
apt install docker.io -y
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu
mkdir -p /home/ubuntu/jenkins_home
chown -R 1000:1000 /home/ubuntu/jenkins_home


docker build -t opsfinal:01 /home/ubuntu
docker run -d -p 8080:8080 -p 50000:50000 -v /home/ubuntu/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --env JAVA_OPTS='-Djenkins.install.runSetupWizard=false' opsfinal:01 


### add jenkins service to consul
tee /etc/consul.d/jenkins-master.json > /dev/null <<"EOF"
{
 "service": {
    "name": "jenkins-master",
    "tags": ["jenkins-master"],
    "port": 8080,
    "check": {
        "id": "tcp",
        "name": "TCP on port 8080",
        "http": "http://localhost:8080",
        "interval": "10s",
        "timeout": "1s"
      }
  }
}
EOF

systemctl daemon-reload
systemctl enable consul.service
systemctl start consul.service

consul reload




tee /opt/prometheus/node-exporter.json > /dev/null <<"EOF"
{
  "service": {
    "name": "node-exporter-jenkins-master",
    "tags": ["node_exporter","prometheus"],
    "port": 9100
}

EOF


systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter



