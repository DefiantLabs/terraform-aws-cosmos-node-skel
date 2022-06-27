#!/bin/bash
mkdir -p horcrux && cd horcrux
wget https://github.com/strangelove-ventures/horcrux/releases/download/v2.0.0-rc3/horcrux_2.0.0-rc3_linux_amd64.tar.gz
tar -zxvf horcrux_2.0.0-rc3_linux_amd64.tar.gz
sudo install horcrux /usr/bin/


case {private_ip} in
    "10.1.1.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|2,tcp://${peer_2_ip}:2222|3" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    "10.1.2.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|1,tcp://${peer_2_ip}:2222|3" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    "10.1.3.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|1,tcp://${peer_2_ip}:2222|2" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    *) echo ${private_ip} not found in map. && exit 1
    ;;
esac


touch ~/.horcrux/share.json

# Setup Service
tee /etc/systemd/system/horcrux.service<<EOF
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
