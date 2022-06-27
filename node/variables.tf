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

variable "node_source" {
  type        = string
  description = "node_source"
}

variable "node_genesis_command" {
  type        = string
  description = "node_genesis_command"
}


variable "node_use_snapshot" {
  type        = bool
  description = "node_use_snapshot"
}

variable "node_snapshot_code" {
  type        = string
  description = "node_snapshot_code"
}


variable "extra_commands" {
  type        = string
  description = "extra_commands"
}

variable "key_pair" {
  type        = string
  description = "key_pair"
}

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

# variable "natgw_id" {
#   description = "natgw_ids"
#   type        = string
# }

variable "subnet_id" {
  description = "public_subnet_id"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "vpc_security_group_ids"
  type        = list(any)
  default     = []
}


variable "bech_prefix" {
  description = "bech_prefix"
  type        = string
}


variable "private_ip" {
  description = "private_ip"
  type        = string
}

variable "az" {
  description = "az"
  type        = string
}