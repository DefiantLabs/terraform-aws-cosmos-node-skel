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
ExecStart=node_exporter --web.listen-address="0.0.0.0:9105"
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable node_exporter
sudo -S systemctl start node_exporter




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


#Hostnames

export IP=$(hostname -I | tr -d '\011\012\013\014\015\040')
case $IP in
    "10.1.1.10") sudo hostnamectl set-hostname horxrux-0 ;;
    "10.1.2.10") sudo hostnamectl set-hostname horxrux-1 ;;
    "10.1.3.10") sudo hostnamectl set-hostname horxrux-2 ;;
    "10.1.1.11") sudo hostnamectl set-hostname monitor-0 ;;
    "10.1.129.10") sudo hostnamectl set-hostname chain-node-0 ;;
    *) echo $IP not found in map. && exit 1
    ;;
esac


sudo tee -a /etc/hosts<<EOF
10.1.1.10 horcrux-0
10.1.2.10 horcrux-1
10.1.3.10 horcrux-2
10.1.1.11 monitor-0
10.1.129.10 chain-node-0
EOF
