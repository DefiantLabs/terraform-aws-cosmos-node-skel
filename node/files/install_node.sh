#!/bin/bash -x
cd /home/ubuntu/

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
