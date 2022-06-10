#!/bin/bash -x
exec > >(tee install_node.log)

# HOME is not set in cloud-config.
export HOME=`getent passwd "$(whoami)" | cut -d: -f6`
cd $HOME

# Add env vars to profile
cat > /etc/profile.d/chain.sh << EOF
export DAEMON_HOME=${node_dir}
export DAEMON_NAME=${node_binary}
export NETWORK=${node_network}
export VERSION=${node_version}
export CHAIN_ID=${node_chain_id}
export DENOM=${node_denom}
export GAS=${minimum-gas-prices}

EOF
chmod a+x /etc/profile.d/chain.sh

. /etc/profile.d/chain.sh

#mount EBS
mkdir -p $DAEMON_HOME
export disk=$(lsblk -J | jq -r '.blockdevices[]  | select(.mountpoint == null) | select(index("children") | not)' | jq -r '.name')
echo "/dev/$disk $DAEMON_HOME xfs defaults 0 0" >> /etc/fstab
mkfs -t xfs /dev/$disk
mount -a

# Install pre-requisites
apt-get install make build-essential chrony -y

# Install Go
git clone https://github.com/udhos/update-golang
cd update-golang
./update-golang.sh
. /etc/profile.d/golang_path.sh
cd ..

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
git checkout $VERSION
make install
cd ..

# Copy binary to cosmovisor
mkdir -p $DAEMON_HOME/cosmovisor/genesis/bin
cp $HOME/go/bin/${node_binary} $DAEMON_HOME/cosmovisor/genesis/bin

${node_binary} init "default" --chain-id $CHAIN_ID

mkdir -p $DAEMON_HOME/data/
mkdir -p $DAEMON_HOME/config/


# Download from snapshot , work in progress
if ${node_use_snapshot} ; then
  ${node_snapshot_code}
fi

${node_genesis}
sed -i "s/^moniker *=.*/moniker = \"${moniker}\"/" $DAEMON_HOME/config/config.toml
sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^max_num_inbound_peers *=.*/max_num_inbound_peers = \"${max_num_inbound_peers}\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^max_num_outbound_peers *=.*/max_num_outbound_peers = \"${max_num_outbound_peers}\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"${minimum-gas-prices}\"/" $DAEMON_HOME/config/app.toml
sed -i "s/^pruning *=.*/pruning = \"${pruning}\"/" $DAEMON_HOME/config/app.toml
sed -i "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"${pruning-keep-recent}\"/" $DAEMON_HOME/config/app.toml
sed -i "s/^pruning-keep-every *=.*/pruning-keep-every = \"${pruning-keep-every}\"/" $DAEMON_HOME/config/app.toml
sed -i "s/^pruning-interval *=.*/pruning-interval = \"${pruning-interval}\"/" $DAEMON_HOME/config/app.toml
sed -i "s/^chain-id *=.*/chain-id = \"$CHAIN_ID\"/" $DAEMON_HOME/config/client.toml
sed -i "s/^pex *=.*/pex = \"${pex}\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^addr_book_strict *=.*/addr_book_strict = \"${addr_book_strict}\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^persistent_peers *=.*/persistent_peers = \"$(${node_peers})\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^seeds *=.*/seeds = \"$(${node_seeds})\"/" $DAEMON_HOME/config/config.toml
sed -i "s/^prometheus *=.*/prometheus = \"${prometheus}\"/" $DAEMON_HOME/config/config.toml

# Setup Service
tee -a /etc/systemd/system/cosmovisor.service<<EOF
[Unit]
Description=cosmovisor
After=network-online.target

[Service]
User=root
ExecStart=$HOME/go/bin/cosmovisor run start
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
