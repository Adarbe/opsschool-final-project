#!/usr/bin/env bash
set -e


node_exporter_ver="0.18.0"

### Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz -O /tmp/node_exporter-0.18.1.linux-amd64.tar.gz
mkdir -p /opt/prometheus
tar zxf /tmp/node_exporter.tgz -C /opt/prometheus

# Configure node exporter service
tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus node exporter
Requires=network-online.target
After=network.target

[Service]
ExecStart=/opt/prometheus/node_exporter-0.18.1.linux-amd64/node_exporter
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/node_exporter.service &>/dev/null << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory /var/lib/node_exporter/textfile_collector \
 --no-collector.infiniband

[Install]
WantedBy=multi-user.target
EOF

tee /var/lib/node_exporter/textfile_collector/metrics.prom > /dev/null <<"EOF"
node_exporter_build_info
node_memory_MemFree_bytes
node_cpu_seconds_total
node_filesystem_avail_bytes
rate(node_cpu_seconds_total{mode="system"}[1m]) 
rate(node_network_receive_bytes_total[1m])
node_disk_io_time_seconds_total
node_network_info

EOF

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service



