data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


provider "aws" {
  default_tags {
    tags = {
      Chain   = "Kujira"
      ChainID = "kaiyo-1"
    }
  }
}

# These are what you can change without breaking.  The other values have deps and need to be changed carefully.
locals {
  # Change these to a trusted pubic SSH Identity.
  sentry_key_pair       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== danb"
  signer_key_pair       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== danb"
  monitor_key_pair      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== danb"
  sentry_instance_type  = "m5.xlarge"
  signer_instance_type  = "t3.micro"
  monitor_instance_type = "t3.small"
  moniker               = "defiantlabs"
  chain                 = "kujira"
  chain-id              = "kaiyo-1"
  ubuntu_ami            = "ami-01f18be4e32df20e2"
  # ubuntu_ami           = data.aws_ami.ubuntu.id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.14.0"

  name = "${local.chain}-${local.chain-id}-vpc"
  cidr = "10.1.0.0/16"

  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets     = ["10.1.129.0/24", "10.1.130.0/24", "10.1.131.0/24"]
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    CIDR = "10.1.0.0/16"
  }
}

#tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group" "node" {
  name        = "node"
  description = "Security group for node"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self        = true
  }

  egress {
    description = "Allow ALL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }

  tags = {
    Name = "node_securitygroup"
  }
}

resource "aws_security_group" "remote_signer" {
  name        = "remote_signer"
  description = "Security group for remote_signer"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self        = true
  }

  egress {
    description = "Allow ALL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }

  tags = {
    Name = "remote_signer_securitygroup"
  }
}

resource "aws_security_group" "monitor" {
  name        = "monitor"
  description = "Security group for monitor"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self        = true
  }

  egress {
    description = "Allow All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }

  tags = {
    Name = "monitor_securitygroup"
  }
}


resource "aws_security_group" "node_p2p_port" {
  name        = "node_p2p_port"
  description = "Allow public to communicate over p2p"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow p2p"
    from_port   = 26656
    to_port     = 26656
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }

  tags = {
    Name = "public_p2p"
  }
}

resource "aws_security_group" "node_rpc_port" {
  name        = "node_rpc_port"
  description = "Allow monitor to communicate with nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow RPC"
    from_port   = 26657
    to_port     = 26657
    protocol    = "tcp"
    security_groups = [
      aws_security_group.monitor.id
    ]
  }

  tags = {
    Name = "node_rpc_port"
  }
}


resource "aws_security_group" "signer_p2p_port" {
  name        = "signer_p2p_port"
  description = "Allow signers to communicate with each other p2p"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow RAFT"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name = "signer_p2p"
  }
}


resource "aws_security_group" "private_validator_port" {
  name        = "private_validator_port"
  description = "Allow communication with the private validator interface"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow Private Validator"
    from_port   = 1234
    to_port     = 1234
    protocol    = "tcp"
    security_groups = [
      aws_security_group.remote_signer.id
    ]
  }

  tags = {
    Name = "private_validator_port"
  }
}


resource "aws_security_group" "exporter_ports" {
  name        = "exporter_ports"
  description = "Allows cosmos_exporter, node_exporter and validator metrics"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [9105, 26660, 9300]
    content {
      description = "Allow cosmos_exporter, node_exporter, and validator metrics"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      security_groups = [
        aws_security_group.monitor.id
      ]
    }
  }

  tags = {
    Name = "cosmos_exporter, node"
  }
}

module "sentry_0" {
  source = "../../node/"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.node.id,
    aws_security_group.node_p2p_port.id,
    aws_security_group.private_validator_port.id,
    aws_security_group.exporter_ports.id
  ]
  subnet_id  = module.vpc.public_subnets[0]
  az         = module.vpc.azs[0]
  private_ip = "10.1.129.10"
  ubuntu_ami = local.ubuntu_ami

  key_pair = local.sentry_key_pair

  instance_type = local.sentry_instance_type
  instance_name = "${local.chain}-${local.chain-id}-Chain-Node"

  instance_ebs_storage_type = "gp3"
  instance_ebs_storage_iops = "3000"
  instance_ebs_storage_size = "300"

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"

  node_source          = "https://github.com/Team-Kujira/core"
  node_binary          = "kujirad"
  node_dir             = "~/.kujira"
  node_network         = "mainnet"
  node_version         = "v0.4.0"
  node_chain_id        = "kaiyo-1"
  node_denom           = "kuji"
  bech_prefix          = "kuji"
  node_genesis_command = "curl -s -o $DAEMON_HOME/config/genesis.json https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/harpoon-4.json"

  # Enable to build from snapshot.
  node_use_snapshot  = false
  node_snapshot_code = <<EOF
      kujirad tendermint unsafe-reset-all
      LATEST=$(curl -s https://snapshots2.polkachu.com/snapshots/ | grep -oE 'kuji/kujia_.*.tar.lz4' | cut -f 1 -d '<' | head -1)
      curl -o - -L https://snapshots2.polkachu.com/snapshots/$LATEST | lz4 -c -d - | tar -xv -C $DAEMON_HOME
      EOF


  # Extra commands to customize your node.
  extra_commands = <<EOF
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.timeout_commit" 1500ms
    dasel put string -f $DAEMON_HOME/config/client.toml -p toml "chain-id" $CHAIN_ID
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning" custom
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-recent" 100
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-keep-every" 0
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-interval" 10
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "minimum-gas-prices" 0.00125ukuji
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.enable" false
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.address" tcp://127.0.0.1:1317
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".api.swagger" false
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.enable" true
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml ".grpc.address" 0.0.0.0:9090


    dasel put string -f $DAEMON_HOME/config/config.toml -p toml "moniker" ${local.moniker}
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".rpc.laddr" tcp://0.0.0.0:26657
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.external_address" $(curl -s ifconfig.me):26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.pex" true
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.laddr" tcp://0.0.0.0:26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.seeds" fd1e3f9baf1922f81bfd9754ddbc4269dbf08264@uni.seed.rhinostake.com:26656
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.persistent_peers" ec41af656b3450050ae27559b66b877373c44861@65.21.122.47:26656,2ae09360327854c79971d07245764626f43fdfc5@38.242.247.46:36656,d3bb05d61ebe83958a5ea2af2abf5d8fce620038@116.202.143.90:26656,c583f7bbfee00ca0ff0208663fe2d07014415ec9@185.213.27.145:36656

    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.addr_book_strict" false
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_inbound_peers" 20
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".p2p.max_num_outbound_peers" 20
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".instrumentation.prometheus" true
    dasel put string -f $DAEMON_HOME/config/config.toml -p toml ".instrumentation.prometheus_listen_addr" 0.0.0.0:26660

  EOF

}

module "horcrux_0" {
  source = "../../horcrux/"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.remote_signer.id,
    aws_security_group.signer_p2p_port.id,
    aws_security_group.exporter_ports.id
  ]
  subnet_id   = module.vpc.private_subnets[0]
  private_ip  = "10.1.1.10"
  peer_1_ip   = "10.1.2.10"
  peer_2_ip   = "10.1.3.10"
  sentry_1_ip = "10.1.129.10"
  ubuntu_ami  = local.ubuntu_ami
  key_pair    = local.signer_key_pair

  instance_type = local.signer_instance_type
  instance_name = "${local.chain}-${local.chain-id}-horcrux_0"
  natgw_id      = module.vpc.natgw_ids[0]
  node_chain_id = local.chain-id

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"
}

module "horcrux_1" {
  source = "../../horcrux/"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.remote_signer.id,
    aws_security_group.signer_p2p_port.id,
    aws_security_group.exporter_ports.id
  ]
  subnet_id   = module.vpc.private_subnets[1]
  private_ip  = "10.1.2.10"
  peer_1_ip   = "10.1.1.10"
  peer_2_ip   = "10.1.3.10"
  sentry_1_ip = "10.1.129.10"
  ubuntu_ami  = local.ubuntu_ami
  key_pair    = local.signer_key_pair

  instance_type = local.signer_instance_type
  instance_name = "${local.chain}-${local.chain-id}-horcrux_1"
  natgw_id      = module.vpc.natgw_ids[0]
  node_chain_id = local.chain-id

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"
}

module "horcrux_2" {
  source = "../../horcrux/"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.remote_signer.id,
    aws_security_group.signer_p2p_port.id,
    aws_security_group.exporter_ports.id
  ]
  subnet_id   = module.vpc.private_subnets[2]
  private_ip  = "10.1.3.10"
  peer_1_ip   = "10.1.1.10"
  peer_2_ip   = "10.1.2.10"
  sentry_1_ip = "10.1.129.10"
  ubuntu_ami  = local.ubuntu_ami
  key_pair    = local.signer_key_pair

  instance_type = local.signer_instance_type
  instance_name = "${local.chain}-${local.chain-id}-horcrux_2"
  natgw_id      = module.vpc.natgw_ids[0]
  node_chain_id = local.chain-id

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"
}


module "monitor_0" {
  source = "../../monitor/"

  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = [
    aws_security_group.monitor.id
  ]
  subnet_id   = module.vpc.private_subnets[0]
  node_denom  = "kuji"
  bech_prefix = "kuji"
  private_ip  = "10.1.1.11"
  peer_1_ip   = "10.1.1.10"
  peer_2_ip   = "10.1.2.10"
  sentry_1_ip = "10.1.129.10"
  ubuntu_ami  = local.ubuntu_ami
  key_pair    = local.signer_key_pair

  instance_type = local.signer_instance_type
  instance_name = "${local.chain}-${local.chain-id}-monitor_0"
  natgw_id      = module.vpc.natgw_ids[0]
  node_chain_id = local.chain-id

  instance_root_storage_type = "gp3"
  instance_root_storage_iops = "3000"
  instance_root_storage_size = "20"
}
