
provider "aws" {
  region = "us-east-1"
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


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



resource "aws_key_pair" "node" {
  key_name   = "node"
  public_key = var.key_pair
}

resource "aws_security_group" "shared_application_security_group" {
  name_prefix = "application_sg"
  description = "Allow ssh between in local security group"

  vpc_id = var.vpc_id
  ingress {
    from_port = 22
    to_port   = 22
    self      = true
    protocol  = "tcp"
  }
}



resource "aws_s3_object" "install_node" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_node.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_node.sh", {
      node_network         = var.node_network
      node_binary          = var.node_binary
      node_source          = var.node_source
      node_dir             = var.node_dir
      node_version         = var.node_version
      node_chain_id        = var.node_chain_id
      node_denom           = var.node_denom
      node_genesis_command = var.node_genesis_command
      node_use_snapshot    = var.node_use_snapshot
      node_snapshot_code   = var.node_snapshot_code
      extra_commands       = var.extra_commands

    })
  )
  etag = filemd5("${path.module}/files/install_node.sh")
}

resource "aws_s3_object" "install_monitor" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_monitor.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_monitor.sh", {
      node_denom = var.node_denom
    })
  )
  etag = filemd5("${path.module}/files/install_monitor.sh")
}

resource "aws_s3_object" "prometheus_conf" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "prometheus.yml"
  content_base64 = base64encode(
    file("${path.module}/files/prometheus.yml")
  )
  etag = filemd5("${path.module}/files/prometheus.yml")
}

resource "aws_s3_object" "dashboard" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "dashboard.yml"
  content_base64 = base64encode(
    file("${path.module}/files/dashboard.yml")
  )
  etag = filemd5("${path.module}/files/dashboard.yml")
}

resource "aws_s3_object" "datasource" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "datasource.yml"
  content_base64 = base64encode(
    file("${path.module}/files/datasource.yml")
  )
  etag = filemd5("${path.module}/files/datasource.yml")
}


#Application resources
resource "aws_s3_bucket" "conf_bucket" {
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_21
  #checkov:skip=CKV_AWS_52
}

resource "aws_s3_bucket_server_side_encryption_configuration" "conf_bucket" {
  bucket = aws_s3_bucket.conf_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "conf_bucket_policy" {
  bucket = aws_s3_bucket.conf_bucket.id
  policy = templatefile("${path.module}/files/application_bucket_policy.json", { application_instance_role_arn = aws_iam_role.application_instance_role.arn, backup_bucket_arn = aws_s3_bucket.conf_bucket.arn })
}

resource "aws_iam_role" "application_instance_role" {
  name_prefix           = "application_instance_role"
  force_detach_policies = true
  assume_role_policy    = templatefile("${path.module}/files/application_instance_assume_role_policy.json", { dns_suffix = data.aws_partition.current.dns_suffix })
}

resource "aws_iam_role_policy" "application_instance_role_policy" {
  name_prefix = "application_instance_elb_policy"
  role        = aws_iam_role.application_instance_role.id
  policy      = templatefile("${path.module}/files/application_instance_role_policy.json", { partition = data.aws_partition.current.partition })
}

resource "aws_iam_role_policy_attachment" "application_instance_role_ssm_attachment" {
  role       = aws_iam_role.application_instance_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "application_instance_profile" {
  name_prefix = "application_instance_profile"
  role        = aws_iam_role.application_instance_role.name
}


resource "aws_security_group" "application_security_group" {
  name_prefix = "application_sg"
  description = "Allow ssh, http ingress"

  vpc_id = var.vpc_id
  ingress {
    from_port   = 26656
    to_port     = 26656
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 26657
    to_port     = 26657
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    from_port   = 9091
    to_port     = 9091
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    from_port   = 1317
    to_port     = 1317
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }
}



resource "aws_instance" "application_instance" {
  #checkov:skip=CKV_AWS_79
  #checkov:skip=CKV_AWS_8
  ami = "ami-01f18be4e32df20e2"
  # ami           = data.aws_ami.ubuntu.id
  key_name      = aws_key_pair.node.key_name
  subnet_id     = var.subnet_id
  private_ip    = "10.0.101.11"
  instance_type = var.instance_type
  vpc_security_group_ids = [
    aws_security_group.application_security_group.id,
    aws_security_group.shared_application_security_group.id
  ]
  iam_instance_profile        = aws_iam_instance_profile.application_instance_profile.name
  associate_public_ip_address = true

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = var.instance_ebs_storage_type
    volume_size = var.instance_ebs_storage_size
    iops        = var.instance_ebs_storage_iops
  }

  root_block_device {
    volume_type = var.instance_root_storage_type
    volume_size = var.instance_root_storage_size
    iops        = var.instance_root_storage_iops
  }

  user_data = templatefile("${path.module}/files/application-cloud-config.yml", {
    conf_bucket = aws_s3_bucket.conf_bucket.bucket
  })

  lifecycle {
    ignore_changes = [
      ebs_block_device
    ]
  }
  # Don't create instance untill network has internet.
  tags = {
    Name    = "${var.instance_name}"
    GATEWAY = var.natgw_id
  }
}
