# See notes in ec2_leader.tf

# nuke all of this and start-over with:
# terraform taint 'aws_instance.worker[0]'
# terraform taint 'cloudflare_record.ec2_worker_dns[0]'
# aws s3 cp etc/user_data.sh s3://docker-swarm-chaos/
# terraform apply -target aws_instance.worker -target cloudflare_record.ec2_worker_dns -var-file chaos.tfvars

resource "aws_instance" "worker" {
  count = var.worker_nodes >= 1 ? var.worker_nodes : 0

  instance_type               = var.instance_type
  associate_public_ip_address = true
  ami                         = var.ami
  key_name                    = var.key_name
  vpc_security_group_ids      = [module.vpc.default_security_group_id]
  subnet_id                   = local.random_public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data_base64 = base64encode(templatefile("${path.module}/etc/bootstrap.sh", {
    CONFIG_BUCKET = "docker-swarm-${var.environment}",
    ENV           = var.environment,
    HOSTNAME      = "${var.environment}-w${count.index + 1}.${var.site_domain}", # e.g. dev-w1.mycompany.app
    LEADER        = "false",
    MANAGER       = "false",
    WORKER        = "true",
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
    Name   = "${var.environment}-w${count.index + 1}"
    Worker = "True"
  })
}

