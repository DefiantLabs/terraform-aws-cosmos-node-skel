

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_object" "install_monitor" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_monitor.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_monitor.sh", {
      node_denom  = var.node_denom
      bech_prefix = var.bech_prefix
      node_chain_id = var.node_chain_id
      private_ip    = var.private_ip
      peer_1_ip     = var.peer_1_ip
      peer_2_ip     = var.peer_2_ip
      sentry_1_ip   = var.sentry_1_ip
    })
  )
  etag = filemd5("${path.module}/files/install_monitor.sh")
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
}

resource "aws_s3_object" "cosmos_validator" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "cosmos_validator.json"
  content_base64 = base64encode(
    file("${path.module}/files/cosmos_validator.json")
  )
  etag = filemd5("${path.module}/files/cosmos_validator.json")
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



resource "aws_key_pair" "monitor" {
  key_name_prefix = "monitor"
  public_key      = var.key_pair
}


#Application resources

#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "conf_bucket" {

}


resource "aws_s3_bucket_public_access_block" "conf_bucket" { 
  bucket = aws_s3_bucket.conf_bucket.id
  block_public_acls = true
  block_public_policy = true 
  ignore_public_acls = true
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

resource "aws_instance" "application_instance" {
  ami = var.ubuntu_ami
  key_name               = aws_key_pair.monitor.key_name
  subnet_id              = var.subnet_id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids
  private_ip             = var.private_ip
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }  

  iam_instance_profile = aws_iam_instance_profile.application_instance_profile.name

  root_block_device {
    volume_type = var.instance_root_storage_type
    volume_size = var.instance_root_storage_size
    iops        = var.instance_root_storage_iops
    encrypted = true
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
