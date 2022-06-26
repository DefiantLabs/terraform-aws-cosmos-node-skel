#!/bin/bash
mkdir -p horcrux && cd horcrux
wget https://github.com/strangelove-ventures/horcrux/releases/download/v2.0.0-rc3/horcrux_2.0.0-rc3_linux_amd64.tar.gz
tar -zxvf horcrux_2.0.0-rc3_linux_amd64.tar.gz
sudo install horcrux /usr/bin/

# 1
horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|2,tcp://${peer_2_ip}:2222|3" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms


# Setup Service
tee -a /etc/systemd/system/horcrux.service<<EOF
[Unit]
Description=horcrux MPC Signer node
After=network-online.target

[Service]
User=ubuntu
ExecStart=/usr/bin/horcrux cosigner start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable horcrux
# sudo -S systemctl start horcrux
