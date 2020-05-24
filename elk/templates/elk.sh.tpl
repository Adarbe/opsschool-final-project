#!/usr/bin/env bash
set -e

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Installing dependencies..."
apt-get -q update
apt-get -yq install unzip dnsmasq

echo "Configuring dnsmasq..."
cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EODMCF

systemctl restart dnsmasq

cat << EOF >/etc/systemd/resolved.conf
[Resolve]
DNS=127.0.0.1
Domains=~consul
EOF

systemctl restart systemd-resolved.service

echo "Fetching Consul..."
cd /tmp
curl -sLo consul.zip https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
mv consul /usr/local/bin/consul

# Setup Consul
mkdir -p /opt/consul
mkdir -p /etc/consul.d
mkdir -p /run/consul
tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "advertise_addr": "$PRIVATE_IP",
  "data_dir": "/opt/consul",
  "datacenter": "opsschool-final-project",
  "encrypt": "uDBV4e+LbFW3019YKPxIrg==",
  "log_level": "INFO",
  "ui": true,
  "disable_remote_exec": true,
  "disable_update_check": true,
  "leave_on_terminate": true,
  "retry_join": ["provider=aws tag_key=consul_server tag_value=true"],
   ${config}
}
EOF



# Create user & grant ownership of folders
useradd consul
chown -R consul:consul /opt/consul /etc/consul.d /run/consul


# Configure consul service
tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=consul
Group=consul
PIDFile=/run/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2
ExecStart=/usr/local/bin/consul agent -pid-file=/run/consul/consul.pid -config-dir=/etc/consul.d
ExecReload=/bin/kill -s HUP \$MAINPID
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable consul.service
systemctl start consul.service




# Install Consul_exporter 

wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz -O /tmp/node_exporter.tgz
mkdir -p /opt/prometheus
tar zxf /tmp/node_exporter.tgz -C /opt/prometheus



# Configure consul_exporter service
tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus node exporter
Wants=network-online.target
After=network-online.target


[Service]
ExecStart=/opt/prometheus/node_exporter-0.18.1.linux-amd64/node_exporter
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service


### add jenkins service to consul
tee /etc/consul.d/elasticsearch.json > /dev/null <<"EOF"
{
  "service": {
      "name": "elasticsearch-9200",
      "port": 9200,
      "check": {
          "id": "elasticsearch-health",
          "name": "HTTP health",
          "http": "http://localhost:9200/_cluster/health",
          "interval": "10s",
          "timeout": "1s"
      }
    }
}
EOF



tee /etc/consul.d/logstash.json > /dev/null <<"EOF"
{
  "service": {
      "name": "logstash_ELK",
      "port": 5044,
      "check": {
          "id": "logstash-health",
          "name": "HTTP health",
          "http": "http://localhost:5044",
          "interval": "10s",
          "timeout": "1s"
      }
    }
}
EOF


tee /etc/consul.d/kibana.json > /dev/null <<"EOF"
{
  "service": {
      "name": "kibana_ELK",
      "port": 5601,
      "check": {
          "id": "kibana-health",
          "name": "HTTP health",
          "http": "http://localhost:5601",
          "interval": "10s",
          "timeout": "1s"
      }
    }
}
EOF



consul reload