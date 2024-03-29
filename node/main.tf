

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "node" {
  key_name_prefix = "node"
  public_key      = var.key_pair
}


resource "aws_s3_object" "install_node" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_node.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_node.sh", {
      node_network         = var.node_network
      bech_prefix = var.bech_prefix
      node_binary          = var.node_binary
      node_source          = var.node_source
      node_dir             = var.node_dir
      node_version         = var.node_version
      node_chain_id        = var.node_chain_id
      node_denom           = var.node_denom
      node_use_snapshot    = var.node_use_snapshot
      node_snapshot_code   = var.node_snapshot_code
      extra_commands       = var.extra_commands

    })
  )
  etag = filemd5("${path.module}/files/install_node.sh")
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_object" "mount_ebs" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "mount_ebs.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/mount_ebs.sh", {
      node_dir             = var.node_dir
    })
  )
  etag = filemd5("${path.module}/files/mount_ebs.sh")
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_object" "install_node_exporter" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_node_exporter.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_node_exporter.sh", {
      node_chain_id = var.node_chain_id
    })
  )
  etag = filemd5("${path.module}/files/install_node_exporter.sh")
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_object" "install_cosmos_exporter" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_cosmos_exporter.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_cosmos_exporter.sh", {
      node_chain_id = var.node_chain_id
      node_denom  = var.node_denom
      bech_prefix = var.bech_prefix
    })
  )
  etag = filemd5("${path.module}/files/install_cosmos_exporter.sh")
  lifecycle {
    ignore_changes = all
  }
}

#Application resources
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "conf_bucket" {

}

resource "aws_s3_bucket_public_access_block" "conf_bucket" {
  bucket                  = aws_s3_bucket.conf_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
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

resource "aws_eip" "application_instance" {
  vpc = true

  instance                  = aws_instance.application_instance.id
  associate_with_private_ip = aws_instance.application_instance.private_ip
  tags = {
    Name = "Node-application-instance"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.node_data.id
  instance_id = aws_instance.application_instance.id
}

#tfsec:ignore:aws-ebs-encryption-customer-key
resource "aws_ebs_volume" "node_data" {
  size              = var.instance_ebs_storage_size
  availability_zone = var.az
  encrypted = true
  iops = var.instance_ebs_storage_iops
  type = var.instance_ebs_storage_type
  tags = {
    Snapshot = "true"
  }
}

resource "aws_instance" "application_instance" {
  ami = var.ubuntu_ami
  key_name               = aws_key_pair.node.key_name
  subnet_id              = var.subnet_id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids
  private_ip             = var.private_ip
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  iam_instance_profile        = aws_iam_instance_profile.application_instance_profile.name

  root_block_device {
    volume_type = var.instance_root_storage_type
    volume_size = var.instance_root_storage_size
    iops        = var.instance_root_storage_iops
    encrypted   = true
  }

  user_data = templatefile("${path.module}/files/application-cloud-config.yml", {
    conf_bucket = aws_s3_bucket.conf_bucket.bucket
  })

  lifecycle {
    ignore_changes = [
      ebs_block_device
    ]
  }
  tags = {
    Name = "${var.instance_name}"
  }
}

