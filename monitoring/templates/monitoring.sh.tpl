#!/usr/bin/env bash
set -e


### add pro + gra service to consul
sudo tee /etc/consul.d/monitoring-3000.json > /dev/null <<"EOF"
{
  "service": {
    "id": "monitoring_grafana",
    "name": "monitoring_grafana",
    "tags": ["grafana"],
    "port": 3000,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 3000",
        "tcp": "localhost:3000",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

sudo tee /etc/consul.d/monitoring-9090.json > /dev/null <<"EOF"
{
  "service": {
    "id": "monitoring_prometheus",
    "name": "monitoring_server_prometheus",
    "tags": ["prometheus"],
    "port": 9090,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 9090",
        "tcp": "localhost:9090",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF


sudo consul reload





mkdir -p /opt/final_monitoring/prometheus
chown -R ubuntu:ubuntu /opt/final_monitoring /run/ubuntu

tee /opt/final_monitoring/prometheus/prometheus.yml > /dev/null <<EOF

global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"


scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']


  - job_name: 'node-exporter'
    consul_sd_configs:
    static_configs:
    - targets: ['localhost:9100']


EOF
