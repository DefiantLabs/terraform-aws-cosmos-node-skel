#!/bin/bash -x
exec > >(tee install_node.log)

# HOME is not set in cloud-config.
# export ROOT_DIR=`getent passwd "$(whoami)" | cut -d: -f6`
export HOME=/home/ubuntu
cd $HOME

# Add env vars to profile
sudo tee /etc/profile.d/chain.sh<<EOF
export DAEMON_HOME=${node_dir}
export DAEMON_NAME=${node_binary}
export NETWORK=${node_network}
export NODE_VERSION=${node_version}
export CHAIN_ID=${node_chain_id}
export DENOM=${node_denom}

EOF
sudo chmod a+x /etc/profile.d/chain.sh

. /etc/profile.d/chain.sh

#mount EBS
mkdir -p $DAEMON_HOME
export disk=$(lsblk -J | jq -r '.blockdevices[]  | select(.mountpoint == null) | select(index("children") | not)' | jq -r '.name')
sudo sh -c "echo /dev/$disk $DAEMON_HOME xfs defaults 0 0 >> /etc/fstab"
sudo mkfs -t xfs /dev/$disk
sudo mount -a
sudo chown -R ubuntu $DAEMON_HOME /home/ubuntu/


# Install pre-requisites
sudo apt-get install make build-essential chrony -y

# Install Go
git clone https://github.com/udhos/update-golang
cd update-golang
sudo ./update-golang.sh
. /etc/profile.d/golang_path.sh
cd ..

# Install dasel to modify toml files.
RELEASE="https://github.com/TomWright/dasel/releases/download/v1.24.3/dasel_linux_amd64"
wget $RELEASE
chmod 755 dasel_linux_amd64
sudo mv dasel_linux_amd64 /usr/bin/dasel


# Setup cosmovisor
git clone https://github.com/cosmos/cosmos-sdk.git
cd cosmos-sdk
git checkout cosmovisor
make cosmovisor
mkdir -p $HOME/go/bin/
cp $HOME/cosmos-sdk/cosmovisor/cosmovisor $HOME/go/bin/cosmovisor
cd ..


# Build Node from source
git clone ${node_source}
cd $(basename ${node_source} | cut -d "." -f1)
git fetch
git checkout $NODE_VERSION
make install
cd ..

# Copy binary to cosmovisor
mkdir -p $DAEMON_HOME/cosmovisor/genesis/bin
mkdir -p $DAEMON_HOME/cosmovisor/upgrades
cp $HOME/go/bin/${node_binary} $DAEMON_HOME/cosmovisor/genesis/bin

${node_binary} init "default" --chain-id $CHAIN_ID

mkdir -p $DAEMON_HOME/data/
mkdir -p $DAEMON_HOME/config/


# Download from snapshot , work in progress
if ${node_use_snapshot} ; then
  ${node_snapshot_code}
fi

${node_genesis_command}
${extra_commands}

# Setup Service
sudo tee /etc/systemd/system/cosmovisor.service<<EOF
[Unit]
Description=cosmovisor
After=network-online.target

[Service]
User=ubuntu
ExecStart=$HOME/go/bin/cosmovisor run start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=$DAEMON_NAME"
Environment="DAEMON_HOME=$DAEMON_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable cosmovisor
sudo -S systemctl start cosmovisor


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
ExecStart=/usr/bin/cosmos-exporter --denom u${node_denom} --denom-coefficient 1000000 --bech-prefix ${bech_prefix}
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable cosmos-exporter
sudo -S systemctl start cosmos-exporter