#!/bin/bash
cd /home/ubuntu/
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
