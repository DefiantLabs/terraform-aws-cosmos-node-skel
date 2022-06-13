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

module "kujira_harpoon4" {
  source = "../../"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.node.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  key_pair = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== node"

  instance_type = "m5.xlarge"
  instance_name = "Node"

  instance_ebs_storage_type = "gp3"
  instance_ebs_storage_iops = "3000"
  instance_ebs_storage_size = "300"

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"

  node_source          = "https://github.com/Team-Kujira/core"
  node_binary          = "kujirad"
  node_dir             = "~/.kujira"
  node_network         = "testnet"
  node_version         = "v0.4.0"
  node_chain_id        = "harpoon-4"
  node_denom           = "kuji"
  bech_prefix           = "kuji"
  node_genesis_command = "curl -s -o $DAEMON_HOME/config/genesis.json https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/harpoon-4.json"

  # Enable to build from snapshot.
  node_use_snapshot  = false
  node_snapshot_code = <<EOF
      kujirad tendermint unsafe-reset-all
      LATEST=$(curl -s https://snapshots2.polkachu.com/snapshots/ | grep -oE 'kujira/kujira_.*.tar.lz4' | cut -f 1 -d '<' | head -1)
      curl -o - -L https://snapshots2.polkachu.com/snapshots/$LATEST | lz4 -c -d - | tar -xv -C $DAEMON_HOME
      EOF

  # Extra commands to customize your node.
  extra_commands = <<EOF
  # Custom commands from https://docs.kujira.app/run-a-node
    wget https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/addrbook.json -O $DAEMON_HOME/config/addrbook.json
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.timeout_commit" 1500ms

    dasel put string -f $DAEMON_HOME/config/client.toml -p toml "chain-id" $CHAIN_ID
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning" custom
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-recent" 100
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-every" 0
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-interval" 10
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "minimum-gas-prices" 0.00125ukuji
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.enable" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.address" tcp://0.0.0.0:1317
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.swagger" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.enable" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.address" 0.0.0.0:9090


    dasel put string -f $DAEMON_HOME/config/config.toml -p toml "moniker" DefiantLabs
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".rpc.laddr" tcp://0.0.0.0:26657
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.external_address" $(curl -s ifconfig.me):26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.pex" true
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.laddr" tcp://0.0.0.0:26656

    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.addr_book_strict" false
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_inbound_peers" 80
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_outbound_peers" 80
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".instrumentation.prometheus" true

  EOF

}
