variable "node_chain_id" {
  type        = string
  description = "node_chain_id"
}

variable "private_ip" {
  type        = string
  description = "private_ip"
}

variable "peer_1_ip" {
  type        = string
  description = "peer_1_ip"
}


variable "peer_2_ip" {
  type        = string
  description = "peer_2_ip"
}


variable "sentry_1_ip" {
  type        = string
  description = "sentry_1_ip"
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

variable "instance_root_storage_type" {
  type        = string
  description = "The application instance EBS storage type for the EBS block device"
  default     = "standard"
}

variable "instance_root_storage_size" {
  type        = number
  description = "The application instance root storage size for the root block device"
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

variable "vpc_security_group_ids" {
  description = "vpc_security_group_ids"
  type        = list(any)
  default     = []
}

variable "ubuntu_ami" {
  description = "ubuntu_ami"
  type        = string
}

variable "extra_commands" {
  type        = string
  description = "extra_commands"
  default = "sleep 1"
}