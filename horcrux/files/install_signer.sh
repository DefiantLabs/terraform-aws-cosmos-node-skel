#!/bin/bash
cd /home/ubuntu/

# Install pre-requisites
sudo apt-get install make build-essential chrony -y

# Install Go
git clone https://github.com/udhos/update-golang
cd update-golang
sudo ./update-golang.sh
. /etc/profile.d/golang_path.sh
cd ..

# Build Node from source
export source="https://github.com/strangelove-ventures/horcrux.git"
git clone $source
cd $(basename $source | cut -d "." -f1)
git fetch
git checkout
make install
cd ..

export IP=$(hostname -I | tr -d '\011\012\013\014\015\040')
case $IP in
    "10.1.1.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|2,tcp://${peer_2_ip}:2222|3" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    "10.1.2.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|1,tcp://${peer_2_ip}:2222|3" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    "10.1.3.10") horcrux config init ${node_chain_id} "tcp://${sentry_1_ip}:1234" -c -p "tcp://${peer_1_ip}:2222|1,tcp://${peer_2_ip}:2222|2" -l "tcp://${private_ip}:2222" -t 2 --timeout 1500ms
    ;;
    *) echo $IP not found in map. && exit 1
    ;;
esac


touch ~/.horcrux/share.json

# Setup Service
sudo tee /etc/systemd/system/horcrux.service<<EOF
[Unit]
Description=horcrux MPC Signer node
After=network-online.target

[Service]
User=ubuntu
ExecStart=$HOME/go/bin/horcrux cosigner start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable horcrux
# sudo -S systemctl start horcrux
