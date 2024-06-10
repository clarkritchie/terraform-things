# In Docker Swarm, the recommendation is that there is an odd number of Leader + Manager nodes (the sum of these),
# totalling no less than 3 and no more than 5.
#
# The reason this code is arranged the way it is is to allow for flexibility when doing no-downtime changes in production,
# since changing an EC2 instance type would destry then re-create the instance.  You would want to do this in phases.
#
# - Drain all of the containers on Manager Group A so that those instances become idle
# - Upgrade Manager Group A
# - Bring Manager Group A back up
# - Repeat for Group B
# - Etc.
#
# Remember that Swarm leadership can be transferred from any node that is a Manager, so there is no guarantee that this
# aws_instance is indeed the Leader in a long-lived cluster.

# force these resrouces to be re-created with:
# - terraform taint aws_instance.ec2_leader
# - terraform taint 'aws_instance.ec2_group_a[0]'
# - terraform taint 'aws_instance.ec2_group_b[0]'

# Instance types can be listed with:  aws ec2 describe-instance-type-offerings --region us-west-1 | jq '.' | grep InstanceType

resource "aws_instance" "ec2_leader" {
  instance_type          = var.instance_type
  ami                    = var.ami
  key_name               = var.key_name
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = local.random_public_subnet_id # randomly places it in one of the public subnets
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  # instead of setting associate_public_ip_address = true, we are going to try using the EIP (see below)

  # any env var that is referenced in the user data script must be defined here, even if it is irrelevant
  user_data_base64 = base64encode(templatefile("${path.module}/etc/bootstrap.sh", {
    CONFIG_BUCKET = "docker-swarm-${var.environment}",
    ENV           = var.environment,
    HOSTNAME      = "${var.environment}.${var.site_domain}", # e.g. dev.mycompany.app
    LEADER        = "true",
    MANAGER       = "false",
    WORKER        = "false",
    REGION        = var.aws_region
  }))

  metadata_options {
    http_tokens = "required" # Instance Metadata Service Version 2 (IMDSv2)
  }

  root_block_device {
    volume_size = 100 # gb
    # TODO volume_type = "gp3"
    encrypted = true
  }

  tags = merge(local.tags, {
    Name   = "${var.environment}"
    Leader = "True"
  })

  # the bool for user_data_replace_on_change does not seem to work as expected
  # user_data_replace_on_change = var.user_data_replace_on_change
  # this setting instructs Terraform to ignore changes to the user_data attribute of the aws_instance resource
  lifecycle {
    ignore_changes = [user_data, user_data_base64] # supposedly includes support for base64, user_data_base64 is a guess
  }
}

resource "aws_eip" "leader_ip" {
  instance = aws_instance.ec2_leader.id
  tags = {
    Region      = aws_instance.ec2_leader.availability_zone
    Environment = var.environment
    Terraform   = "True"
  }
}