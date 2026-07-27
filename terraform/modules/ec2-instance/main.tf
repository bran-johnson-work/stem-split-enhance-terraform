# Need to create a keypair on AWS console first
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type           = var.root_block_device.volume_type
    volume_size           = var.root_block_device.volume_size
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  disable_api_termination = var.disable_api_termination
  monitoring              = var.monitoring
  user_data               = var.user_data

  # Enforce IMDSv2 (token required — blocks legacy IMDSv1/SSRF-style GET reads).
  # hop_limit defaults to 1; set to 2 for hosts that run containers on the Docker
  # bridge network, so boto3 inside a container can still reach the instance profile.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_hop_limit
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-ec2-instance"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}

# Optional Elastic IP — allocated and associated only when create_eip = true, so
# callers get a stable public address without declaring EIP resources themselves.
resource "aws_eip" "eip" {
  count = var.create_eip ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-eip"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "eip" {
  count = var.create_eip ? 1 : 0

  instance_id   = aws_instance.ec2_instance.id
  allocation_id = aws_eip.eip[0].id
}
