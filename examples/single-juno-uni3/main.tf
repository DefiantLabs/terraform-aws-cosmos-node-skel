module "juno-uni3" {
    source = "/home/socket/code/github/DefiantLabs/terraform-aws-cosmos-node-skel/"
    vpc_cidr = "10.0.0.0/16"
    vpc_name = "node-vpc"
    vpc_azs             = ["us-east-1a"]
    vpc_private_subnets = ["10.0.1.0/24"]
    vpc_public_subnets  = ["10.0.101.0/24"]
    vpc_enable_nat_gateway = true

    node_source = "https://github.com/CosmosContracts/juno.git"
    node_binary = "junod"
    node_dir = "~/.juno"
    moniker = "dltest2"
    node_network = "testnets"
    node_version = "v6.0.0"
    node_chain_id = "uni-3"
    node_denom = "juno"
    minimum-gas-prices = "0.025ujuno"
    node_peers = "curl -s https://raw.githubusercontent.com/CosmosContracts/testnets/main/uni-3/persistent_peers.txt"
    node_genesis = "curl -s https://raw.githubusercontent.com/CosmosContracts/testnets/main/uni-3/genesis.json"
    node_seeds = ""

    pruning = "custom"
    pruning-keep-recent = "100"
    pruning-keep-every = "0"
    pruning-interval = "10"
    max_num_inbound_peers = "80"
    max_num_outbound_peers = "80"
    pex = "true"
    addr_book_strict = "false"
    prometheus = "true"
    node_use_snapshot = true
    node_snapshot_code = <<EOF
      LATEST=$(curl -s https://snapshots2.polkachu.com/snapshots/ | grep -oE 'juno/juno_.*.tar.lz4' | cut -f 1 -d '<' | head -1)
      curl -o - -L https://snapshots2.polkachu.com/snapshots/$LATEST | lz4 -c -d - | tar -xv -C $DAEMON_HOME
      EOF
    key_pair = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrTO9qkF76HhTUTZcEUV8c+p+oyfelTNqqK1hupvz7L/yX1I8Q8NGMRdrmIdRRj8JlAD5qughXVPCDj4HvTD1pLOQNV6E9CxPznOlb3ogQmdVmNvl/gyG8ySUPxldVnbBXZgChdi8xFjjzlHeNy+gIbbxHwsMS4k/Kk0N4s0dtEo2Hxz3VHpafzvpzhRWP0mstgPNWhyNlbwSh7ojx4zYug2mrKd560fcMP8fEx1RgZ5pLrSlLL8NHaJzc4EpiAFbqwS8SFM+HyABWWnjZhm7acdweboE9oahjMa/7UhUTgIN44E/fb1DLiAWARHru9/yaOan4uxzkGmHhtLa/xLjdrq5N9J3TlGGURJGtcHAY80MLPJ6IiYpCIM7JpYHn8eLrH8kbeSDQp6+Y3NtILBMxVxjkZ2UjJDMRQv9iprH5qc0uMP6IILm9x2tdmwpxl+emyDq22rE9JcvSqY4VSVYTpiIwKdJd9P/npAudCJjLCYOjSOUZ41Npb9cYqaYCfPGAu/jNmcoMy0F3wWVqHLDN7ngR+HO4sJiPXY+vcQU8PoMHuYm99jEh0U+TKk6S+KlGGwTAm002LVnKnkCRZSGXgnCJmj0dYiHaL2EhWnzS2TRsTyWhTGO/VOMwCvM+1MuHYMGJexeTPuTkLcbgUgWWtFBWslOn6oONqDPz95SBHQ== sentry"



    # Sentry Settings
    instance_type = "m5.xlarge"
    instance_name = "Node"

    instance_ebs_storage_type = "io2"
    instance_ebs_storage_iops = "9000"
    instance_ebs_storage_size = "300"

    instance_root_storage_type = "gp3"
    instance_root_storage_iops = "3000"
    instance_root_storage_size = "20"

}