variable "moniker" {
  type        = string
  description = "moniker"
}

variable "minimum-gas-prices" {
  type        = string
  description = "minimum-gas-prices"
}

variable "node_network" {
  type        = string
  description = "node_network"
}

variable "node_binary" {
  type        = string
  description = "node_binary"
}

variable "node_dir" {
  type        = string
  description = "node_dir"
}

variable "node_version" {
  type        = string
  description = "node_version"
}

variable "node_chain_id" {
  type        = string
  description = "node_chain_id"
}

variable "node_denom" {
  type        = string
  description = "node_denom"
}

variable "node_seeds" {
  type        = string
  description = "node_seeds"
}

variable "node_source" {
  type        = string
  description = "node_source"
}

variable "node_peers" {
  type        = string
  description = "node_peers"
}

variable "node_genesis" {
  type        = string
  description = "node_genesis"
}


variable "pruning" {
  type        = string
  description = "pruning"
}

variable "pruning-keep-recent" {
  type        = string
  description = "pruning-keep-recent"
}

variable "pruning-keep-every" {
  type        = string
  description = "pruning-keep-every"
}

variable "pruning-interval" {
  type        = string
  description = "pruning-interval"
}

variable "max_num_inbound_peers" {
  type        = string
  description = "max_num_inbound_peers"
}


variable "max_num_outbound_peers" {
  type        = string
  description = "max_num_outbound_peers"
}


variable "node_use_snapshot" {
  type        = bool
  description = "node_use_snapshot"
}

variable "node_snapshot_code" {
  type        = string
  description = "node_snapshot_code"
}

variable "key_pair" {
  type        = string
  description = "key_pair"
}

variable "pex" {
  type        = string
  description = "pex"
}

variable "addr_book_strict" {
  type        = string
  description = "addr_book_strict"
}

variable "prometheus" {
  type        = string
  description = "prometheus"
}

# Sentry Vars
variable "instance_type" {
  type        = string
  description = "The EC2 instance type used for the application"
}

variable "instance_name" {
  type        = string
  description = "The EC2 instance name used for the application"
}

variable "instance_ebs_storage_type" {
  type        = string
  description = "The application instance EBS storage type for the EBS block device"
  default     = "standard"
}

variable "instance_ebs_storage_snapshotid" {
  type        = string
  description = "The application instance EBS storage snapshot for the EBS block device"
  default     = null
}


variable "instance_root_storage_type" {
  type        = string
  description = "The application instance EBS storage type for the EBS block device"
  default     = "standard"
}

variable "instance_ebs_storage_size" {
  type        = number
  description = "The application instance EBS storage size for the EBS block device"
}


variable "instance_root_storage_size" {
  type        = number
  description = "The application instance root storage size for the root block device"
}

variable "instance_ebs_storage_iops" {
  type        = number
  description = "The application instance EBS IOPS for the EBS block device, only valid for volume types io1/io2"
}

variable "instance_root_storage_iops" {
  type        = number
  description = "The application instance EBS IOPS for the EBS block device, only valid for volume types io1/io2"
}

variable "vpc_id" {
  description = "Name to be used on the Default VPC"
  type        = string
}

variable "natgw_id" {
  description = "natgw_ids"
  type        = string
}

variable "subnet_id" {
  description = "public_subnet_id"
  type        = string
}
