
# terraform-aws-cosmos-node-skel
A terraform module to deploy a cosmos node in amazon web services. Check out the examples.  

## AWS Setup
Create IAM User Credentials for dev identity with permission to assume role to terraform_admin
```
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::121212121212-id:role/terraform_admin"
  }
}
```

Create IAM Role for terraform_admin. This role should have the "Administrator" policy attached. Then configure a trust relationship with dev identity.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::121212121212:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```

Create ~/.aws/config
```
[profile dev_identity]
region=us-east-1
output=json


[profile terraform_admin]
source_profile=dev_identity
role_arn=arn:aws:iam::121212121212:role/terraform_admin
region=us-east-1
output=json
```

Use [aws-vault](https://github.com/99designs/aws-vault) to add access key credentials for dev_identity and test

```
aws-vault add dev_identity
aws-vault exec dev_identity -- sts get-caller-identity
```

## Switch to terraform role with aws-vault

```
avsh terraform_admin
```

## Deploy a pre-built example.  
In the examples folder are pre-built configs for common validator setups.  For example to build a single public juno testnet validator you would.

```
cd examples/single-juno-uni-3
terragrunt init
terragrunt plan
terragrunt apply
```

## Customize your own validator.  
Choose a existing example, copy it to a new name, customize the options.  

```
cp examples/single-juno-uni-3 examples/my-custom-validator
```
Customize the values in `examples/my-custom-validator/main.tf` Pay special attention to `extra_commands`.  This the primary spot on how to customize a node.  It can be used to convert a sentry into a validator. dasel allows you to easily modify a toml file, but any shell code should work.
```
  extra_commands = <<EOF
    dasel put string -f $DAEMON_HOME/config/app.toml -p toml "pruning-interval" 10
    ....
  EOF
```

Then run
```
terragrunt init
terragrunt plan
terragrunt apply
```


## Connect to your instance by SSM
There are many ways to connect to an instance in AWS.  A common way is to use SSM.  
[session-manager-working-with-install-plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)  
[aws-ssm-tools](https://github.com/mludvig/aws-ssm-tools)  


```
#add these to your shell (~/.zshrc)
alias ssml="ssm-session --list"
alias ssm="ssm-session $@"
```

```
ssml
ssm i-095fced5ad3bd5adb
sudo su - ec2-user
```

## Connect to your instance by SSH  
Instead of SSM, you can use SSH by doing the following:   
- add port `22` to the ingress section of `resource "aws_security_group" "node"` in `main.tf`.   
- update `key_pair` in `main.tf` with your public key  
- then execute the following command
```
ssh -i private.key ubuntu@ip
```

# Automated Installer
Shortly after you connect, the instacne will run `/home/ec2-user/install_node.sh`.  You can watch the progress by doing `tail -f /home/ec2-user/install_node.log`. Keep in mind this may take a while depending on the snapshot you used.
```
./install_node.sh
```

# Optional - Install Monitoring Software
Prometheus, node_exporter, cosmos_exporter, grafana, dashboards
**Note:** The some aspects of the dashboard require the chain to be fully synced, and the validator to be created.  Make sure you update your node and valoper address in `install_monitor.sh`.  You can connect to grafana by going to http://ip:3000.  The default user/pass is admin/admin. The following dashboard is recomended to be installed manually.  https://grafana.com/grafana/dashboards/15991-cosmos-validator
```
./install_monitor.sh
```

# Watch the cosmovisor logs
If all goes well, you should see your node running and syncing blocks.
```
journalctl -u cosmovisor -f | ccze -A
```

# Query via the RPC (default port: 26657)
This command will let you know when the sync has completed.
```
curl http://localhost:26657/status | jq .result.sync_info.catching_up
```

# Convert into a Validator (juno uni-3 Example)

## Create Operator Key

```
junod keys add operator
```

## Create Validator TX
*You may need to edit some of these values for your chain-id*
```
junod tx staking create-validator \
  --amount 9000000ujunox \
  --commission-max-change-rate "0.1" \
  --commission-max-rate "0.20" \
  --commission-rate "0.1" \
  --min-self-delegation "1" \
  --details "changeme" \
  --pubkey=$(junod run tendermint show-validator) \
  --moniker $MONIKER_NAME \
  --chain-id $CHAIN_ID \
  --gas-prices 0.025ujunox \
  --from $MONIKER_NAME
```

# Frequently Asked Questions:

## How to Get out of jail Juno example

### Do the minimum self delegate
```
junod tx staking delegate junovaloper_address 100000ujunox --fees 5000ujunox --from juno_operator_address --chain-id uni-3
```

### Send the unjail tx
This must be done from a fully synced node.
```
junod tx slashing unjail \
    --from=operator \
    --chain-id=uni-3\
    --gas-prices=0.025ujunox \
    --home=/home/ec2-user/.juno
```

You can check the status by looking at the mintscan TX details.


## How to edit validator details  
```
gaiad tx staking edit-validator cosmosvaloper1qwc7a4kgys2zfswu7a4f5egc0rssep6tdlxu2z --fees 5000uatom --from cosmos1qwc7a4kgys2zfswu7a4f5egc0rssep6tgtjfx3 --chain-id theta-testnet-001 --website http://defiantlabs.net
```


## todo
add bechprefix for cosmos-exporer