# See notes in ec2_leader.tf

resource "aws_instance" "ec2_group_a" {
  # this should not be more than 2
  count = var.group_a_nodes >= 1 ? var.group_a_nodes : 0

  instance_type          = var.instance_type
  ami                    = var.ami
  key_name               = var.key_name
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = local.random_public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  # instead of setting associate_public_ip_address = true, we are going to try using the EIP (see below)

  user_data_replace_on_change = var.user_data_replace_on_change
  user_data_base64 = base64encode(templatefile("${path.module}/etc/bootstrap.sh", {
    CONFIG_BUCKET = "docker-swarm-${var.environment}",
    ENV           = var.environment,
    HOSTNAME      = "${var.environment}-a${count.index + 1}.${var.site_domain}", # e.g. dev-a1.mycompany.app
    LEADER        = "false",
    MANAGER       = "true",
    WORKER        = "false",
    REGION        = var.aws_region
  }))

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 100
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = merge(local.tags, {
    Name    = "${var.environment}-a${count.index + 1}"
    Manager = "True",
    Group   = "A"
  })
}

resource "aws_eip" "ec2_group_a_ips" {
  count    = var.group_a_nodes >= 1 ? var.group_a_nodes : 0
  domain   = "vpc"
  instance = aws_instance.ec2_group_a[count.index].id
  tags = {
    Region      = aws_instance.ec2_group_a[count.index].availability_zone
    Environment = var.environment
    Terraform   = "True"
  }
}

resource "aws_instance" "ec2_group_b" {
  # this should not be more than 2
  count = var.group_b_nodes >= 1 ? var.group_b_nodes : 0

  instance_type          = var.instance_type
  ami                    = var.ami
  key_name               = var.key_name
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = local.random_public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  # instead of setting associate_public_ip_address = true, we are going to try using the EIP (see below)

  user_data_base64 = base64encode(templatefile("${path.module}/etc/bootstrap.sh", {
    CONFIG_BUCKET = "docker-swarm-${var.environment}",
    ENV           = var.environment,
    HOSTNAME      = "${var.environment}-b${count.index + 1}.${var.site_domain}", # e.g. dev-b1.mycompany.app
    LEADER        = "false",
    MANAGER       = "true",
    WORKER        = "false",
    REGION        = var.aws_region
  }))

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 100
    encrypted   = true
  }

  # the bool for user_data_replace_on_change does not seem to work as expected
  # user_data_replace_on_change = var.user_data_replace_on_change
  # this setting instructs Terraform to ignore changes to the user_data attribute of the aws_instance resource
  lifecycle {
    ignore_changes = [user_data, user_data_base64] # supposedly includes support for base64, user_data_base64 is a guess
  }

  tags = merge(local.tags, {
    Name    = "${var.environment}-b${count.index + 1}"
    Manager = "True",
    Group   = "B"
  })
}

resource "aws_eip" "ec2_group_b_ips" {
  count    = var.group_b_nodes >= 1 ? var.group_b_nodes : 0
  domain   = "vpc"
  instance = aws_instance.ec2_group_b[count.index].id
  tags = {
    Region      = aws_instance.ec2_group_b[count.index].availability_zone
    Environment = var.environment
    Terraform   = "True"
  }
}