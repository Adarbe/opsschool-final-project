#!/usr/bin/env bash
set -e

### Install Node Exporter
wget \
  https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz \
  -O /tmp/node_exporter-${node_exporter_version}.linux-amd64.tar.gz

tar zxvf /tmp/node_exporter-${node_exporter_version}.linux-amd64.tar.gz
cp ./node_exporter-${node_exporter_version}.linux-amd64/node_exporter /usr/local/bin


useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

mkdir -p /var/lib/node_exporter/textfile_collector
chown node_exporter:node_exporter /var/lib/node_exporter
chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector

# Configure node exporter service
tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector 

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter.service
systemctl status --no-pager node_exporter
systemctl enable node_exporter.service




