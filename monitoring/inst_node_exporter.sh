#!/bin/bash
set -e

wget \
  https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz \
  -O /tmp/node_exporter-0.18.1.linux-amd64.tar.gz

tar zxvf /tmp/node_exporter-0.18.1.linux-amd64.tar.gz
sudo cp ./node_exporter-0.18.1.linux-amd64/node_exporter /opt/local/bin


sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo chown node_exporter:node_exporter /var/lib/node_exporter
sudo chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector

# Configure node exporter service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
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

sudo systemctl daemon-reload
sudo systemctl start node_exporter
systemctl status --no-pager node_exporter
sudo systemctl enable node_exporter

# tee /var/lib/node_exporter/textfile_collector/metrics.prom > /dev/null <<EOF
# node_exporter_build_info
# node_memory_MemFree_bytes
# node_cpu_seconds_total
# node_filesystem_avail_bytes
# rate(node_cpu_seconds_total{mode="system"}[1m]) 
# rate(node_network_receive_bytes_total[1m])
# node_disk_io_time_seconds_total
# node_network_inf
# EOF



# systemctl daemon-reload
# systemctl start node_exporter
# systemctl status --no-pager node_exporter
# systemctl enable node_exporter