#!/bin/bash
# Cosmos Exporter
wget https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.3.0/cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
tar -zxvf cosmos-exporter_0.3.0_Linux_x86_64.tar.gz
cp cosmos-exporter /usr/bin/
cd ..

# Setup Service
tee -a /etc/systemd/system/cosmos-exporter.service<<EOF
[Unit]
Description=cosmos-exporter
After=network-online.target
[Service]
User=root
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