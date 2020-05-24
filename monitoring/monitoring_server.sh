#!/bin/bash
set -e

sudo chmod 777 /home/ubuntu/monitoring
sudo chmod +x /home/ubuntu/monitoring/inst_docker.sh
/home/ubuntu/monitoring/inst_docker.sh
sudo chmod 767 /var/run/docker.sock
cd /home/ubuntu/monitoring/compose && docker-compose down
cd /home/ubuntu/monitoring/compose && docker-compose up -d



