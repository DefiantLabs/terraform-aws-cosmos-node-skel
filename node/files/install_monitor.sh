export nodeval="nodeval"
export nodeacc="nodeacc"

# Install Monitoring tools
# Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.36.0/prometheus-2.36.0.linux-amd64.tar.gz
tar -zxvf prometheus-2.36.0.linux-amd64.tar.gz
cd prometheus-2.36.0.linux-amd64
sudo mv prometheus /usr/bin/
mkdir -p /etc/prometheus/
sudo cp /home/ubuntu/prometheus.yml /etc/prometheus/prometheus.yml
sudo sed -i "s/nodeval/$nodeval/" /etc/prometheus/prometheus.yml
sudo sed -i "s/nodeacc/$nodeacc/" /etc/prometheus/prometheus.yml
cd ..

# Setup Service
sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=prometheus
After=network-online.target

[Service]
User=ubuntu
ExecStart=prometheus --web.listen-address=0.0.0.0:9094 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path="/home/ubuntu/data/"
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable prometheus
sudo -S systemctl start prometheus



# Prometheus Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar -zxvf node_exporter-1.3.1.linux-amd64.tar.gz
cd node_exporter-1.3.1.linux-amd64
sudo cp node_exporter /usr/bin/
cd ..

# Setup Service
sudo tee /etc/systemd/system/node_exporter.service<<EOF
[Unit]
Description=node_exporter
After=network-online.target

[Service]
User=ubuntu
ExecStart=node_exporter --web.listen-address=":9105"
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable node_exporter
sudo -S systemctl start node_exporter


# Cosmos Exporter
wget https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.3.0/cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
tar -zxvf cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
sudo cp cosmos-exporter /usr/bin/
cd ..

# Setup Service
sudo tee /etc/systemd/system/cosmos-exporter.service<<EOF
[Unit]
Description=cosmos-exporter
After=network-online.target

[Service]
User=ubuntu
ExecStart=cosmos-exporter --denom u${node_denom} --denom-coefficient 1000000 --bech-prefix ${bech_prefix}
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable cosmos-exporter
sudo -S systemctl start cosmos-exporter

# Grafana

sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana

# Install Default Dashboards
mkdir -p /etc/grafana/provisioning/dashboards/
mkdir -p /etc/grafana/provisioning/datasources/
sudo cp /home/ubuntu/dashboard.yml /etc/grafana/provisioning/dashboards/
sudo cp /home/ubuntu/datasource.yml /etc/grafana/provisioning/datasources/
__url='https://raw.githubusercontent.com/kj89/cosmos_node_monitoring/master/grafana/dashboards/cosmos_validator.json'
__file='/etc/grafana/provisioning/dashboards/cosmos_validator.json'
sudo wget -qcO - $__url | jq '.title = "cosmos_validator"' >$__file

sudo -S systemctl daemon-reload
sudo -S systemctl enable grafana-server
sudo -S systemctl start grafana-server