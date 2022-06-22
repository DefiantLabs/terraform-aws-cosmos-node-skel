

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



resource "aws_key_pair" "signer" {
  key_name_prefix   = "signer"
  public_key = var.key_pair
}


resource "aws_s3_object" "install_signer" {
  bucket = aws_s3_bucket.conf_bucket.bucket
  key    = "install_signer.sh"
  content_base64 = base64encode(
    templatefile("${path.module}/files/install_signer.sh", {
      node_network         = var.node_network

    })
  )
  etag = filemd5("${path.module}/files/install_signer.sh")
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

resource "aws_instance" "application_instance" {
  #checkov:skip=CKV_AWS_79
  #checkov:skip=CKV_AWS_8
  ami = "ami-01f18be4e32df20e2"
  # ami           = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.signer.key_name
  subnet_id              = var.subnet_id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile        = aws_iam_instance_profile.application_instance_profile.name

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