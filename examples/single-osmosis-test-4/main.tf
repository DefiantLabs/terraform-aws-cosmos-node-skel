module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.14.0"

  name = "node-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"

  }
}

resource "aws_security_group" "node" {
  name        = "allow_public"
  description = "Allow public to communicate with node"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [26656, 26657, 9090, 9091, 1317, 3000]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_public"
  }
}

module "osmosis_test4" {
  source = "../../"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.node.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  key_pair = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== node"

  instance_type = "m5.xlarge"
  instance_name = "Node"

  instance_ebs_storage_type = "io2"
  instance_ebs_storage_iops = "9000"
  instance_ebs_storage_size = "300"

  instance_root_storage_type = "io2"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"

  node_source          = "https://github.com/osmosis-labs/osmosis.git"
  node_binary          = "osmosisd"
  node_dir             = "~/.osmosisd"
  node_network         = "osmo-test-4"
  node_version         = "v9.0.0"
  node_chain_id        = "osmo-test-4"
  node_denom           = "osmo"
  bech_prefix          = "osmo"
  node_genesis_command = "curl -o - -L  https://github.com/osmosis-labs/networks/raw/main/osmo-test-4/genesis.tar.bz2 | tar -xj -C $DAEMON_HOME/config/"

  # Enable to build from snapshot.
  node_use_snapshot  = false
  node_snapshot_code = <<EOF
      osmosisd tendermint unsafe-reset-all
      URL=`curl https://quicksync.io/osmosis.json|jq -r '.[] |select(.file=="osmotestnet-4-pruned")|select (.mirror=="Netherlands")|.url'`
      curl -o - -L $URL | lz4 -c -d - | tar -xv -C $DAEMON_HOME
      EOF

  # Extra commands to customize your node.
  extra_commands = <<EOF
    dasel put string -f $DAEMON_HOME/config/client.toml -p toml "chain-id" $CHAIN_ID

    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning" custom
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-recent" 100
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-every" 0
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-interval" 10
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "minimum-gas-prices" 0.025uosmo
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.enable" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.address" tcp://0.0.0.0:1317
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.swagger" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.enable" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.address" 0.0.0.0:9090


    dasel put string -f $DAEMON_HOME/config/config.toml -p toml "moniker" dltest1
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".rpc.laddr" tcp://0.0.0.0:26657
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.external_address" $(curl -s ifconfig.me):26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.pex" true
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.laddr" tcp://0.0.0.0:26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.seeds" 0f9a9c694c46bd28ad9ad6126e923993fc6c56b1@137.184.181.105:26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.persistent_peers" 4ab030b7fd75ed895c48bcc899b99c17a396736b@137.184.190.127:26656,3dbffa30baab16cc8597df02945dcee0aa0a4581@143.198.139.33:26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.addr_book_strict" false
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_inbound_peers" 80
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_outbound_peers" 80
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".instrumentation.prometheus" true

  EOF




}
