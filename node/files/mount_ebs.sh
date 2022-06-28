#!/bin/bash -x
exec > >(tee install_node.log)
cd /home/ubuntu/
export DAEMON_HOME=${node_dir}

#mount EBS
mkdir -p $DAEMON_HOME
export disk=$(lsblk -J | jq -r '.blockdevices[]  | select(.mountpoint == null) | select(index("children") | not)' | jq -r '.name')
sudo sh -c "echo /dev/$disk $DAEMON_HOME xfs defaults 0 0 >> /etc/fstab"
sudo mkfs -t xfs /dev/$disk
sudo mount -a
sudo chown -R ubuntu $DAEMON_HOME /home/ubuntu/