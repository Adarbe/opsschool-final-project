#!/usr/bin/env bash
set -e


node_exporter_ver="0.18.0"
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz -O /tmp/node_exporter-0.18.1.linux-amd64.tar.gz
tar zxvf /tmp/node_exporter-0.18.1.linux-amd64.tar.gz
sudo cp /tmp/node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo chown node_exporter:node_exporter /var/lib/node_exporter
sudo chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector

sudo cp /home/ubuntu/monitoring/node_exporter.service /etc/systemd/system/node_exporter.service

rm -rf /tmp/node_exporter-0.18.1.linux-amd64.tar.gz \
./node_exporter-0.18.1.linux-amd64

sudo systemctl daemon-reload
sudo systemctl start node_exporter
systemctl status --no-pager node_exporter
sudo systemctl enable node_exporter