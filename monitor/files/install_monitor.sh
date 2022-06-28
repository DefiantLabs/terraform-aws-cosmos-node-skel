#!/bin/bash
cd /home/ubuntu/
export nodeval="nodeval"
export nodeacc="nodeacc"

# Install Monitoring tools
# Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.36.0/prometheus-2.36.0.linux-amd64.tar.gz
tar -zxvf prometheus-2.36.0.linux-amd64.tar.gz
cd prometheus-2.36.0.linux-amd64
sudo mv prometheus /usr/bin/
sudo mkdir -p /etc/prometheus/
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



# Grafana

sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana

# Install Default Dashboards
sudo mkdir -p /etc/grafana/provisioning/dashboards/
sudo mkdir -p /etc/grafana/provisioning/datasources/
sudo cp /home/ubuntu/datasource.yml /etc/grafana/provisioning/datasources/
sudo cp /home/ubuntu/dashboard.yml /etc/grafana/provisioning/dashboards/
sudo cp /home/ubuntu/cosmos_validator.json /etc/grafana/provisioning/dashboards/


sudo -S systemctl daemon-reload
sudo -S systemctl enable grafana-server
sudo -S systemctl start grafana-server


# Install pre-requisites
sudo apt-get install make build-essential chrony -y

# Install Go
git clone https://github.com/udhos/update-golang
cd update-golang
sudo ./update-golang.sh
. /etc/profile.d/golang_path.sh
cd ..

# Install half-life
git clone https://github.com/strangelove-ventures/half-life.git
cd half-life/
cp config.yaml.example config.yaml
go install

# Setup Service
sudo tee /etc/systemd/system/halflife.service<<EOF
[Unit]
Description=half-life
After=network-online.target

[Service]
User=ubuntu
ExecStart=/home/ubuntu/go/bin/halflife monitor -f /home/ubuntu/half-life/config.yaml
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable halflife
# sudo -S systemctl restart halflife


