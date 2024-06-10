# the AWS UI has a name field, but there is no name attribute
# in Terraform, we have to use tags :-(
resource "aws_eip" "nlb" {
  count  = length(var.azs)
  domain = "vpc"
  tags = {
    # The simple version of this would be:
    # Region      = count.index % 2 == 0 ? var.azs[0] : var.azs[1]
    # Instead, we're nesting 2 ternaries here to guarad against a single AZ
    # Region      = length(var.azs) >= 1 ? count.index % 2 == 0 ? var.azs[0] : var.azs[1] : null
    Region      = var.azs[count.index]
    Environment = var.environment
  }
}


# terraform destroy -target aws_lb.docker_swarm_lb -var-file chaos.tfvars
# terraform plan -target aws_lb.docker_swarm_lb -var-file chaos.tfvars
resource "aws_lb" "docker_swarm_lb" {
  name               = "swarm-${var.environment}-nlb"
  internal           = false
  load_balancer_type = "network"

  # TODO
  # enable_deletion_protection = true

  enable_cross_zone_load_balancing = true

  #
  # Important:  AWS says that a load balancer cannot be attached to
  # multiple subnets in the same Availability Zone
  #
  # Terraform will create the subnets in a loop, alternating azs, e.g.:
  # - module.vpc.public_subnets[0] will be in us-west-2a
  # - module.vpc.public_subnets[1] will be in us-west-2c
  # - module.vpc.public_subnets[2] will be in us-west-2a
  # - module.vpc.public_subnets[3] will be in us-west-2c
  # so the mod operator here is to ensure we pick a subnet from the other
  # az -- e.g. when we're on the first iteration, count.index % 2 is 0,
  # so we assign 2 mappings -- one for subnets [0] and the other for [1],
  # which would mean the LB is attached to subnets in us-west-2a and
  # us-west-2c, which satisfies the AWS constraint above
  #

  subnet_mapping {
    subnet_id     = module.vpc.public_subnets[0]
    allocation_id = aws_eip.nlb[0].allocation_id
  }

  subnet_mapping {
    subnet_id     = module.vpc.public_subnets[1]
    allocation_id = aws_eip.nlb[1].allocation_id
  }

  # TODO tags
}

# It's not clear if we want an HTTP listener, since CloudFlare does SSL termination
# terraform plan -target aws_lb_listener.apps_http -var-file chaos.tfvars
resource "aws_lb_listener" "apps_http" {
  load_balancer_arn = aws_lb.docker_swarm_lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_swarm_tg.arn
  }
}

# It's not clear why we need an HTTPS listener, since CloudFlare does SSL termination
# terraform plan -target aws_lb_listener.apps_https -var-file chaos.tfvars
resource "aws_lb_listener" "apps_https" {
  load_balancer_arn = aws_lb.docker_swarm_lb.arn
  port              = "443"
  protocol          = "TCP" # no additional certificate info is required

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_swarm_tg.arn
  }
}

# create a target group for each lb
# terraform plan -target aws_lb_target_group.docker_swarm_tg -var-file chaos.tfvars
resource "aws_lb_target_group" "docker_swarm_tg" {
  name     = "${var.environment}-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  # this will go against Nginx
  health_check {
    port              = 80
    healthy_threshold = 2 # default is 3, minimum is 2
    interval          = 5 # defaults to 30
    path              = "/test"
    matcher           = "418" # this can also be a range, e.g. "200-299"
    timeout           = 5     # defaults to 30
  }
}

# since we're creating the EC2 leader indepenent of the managers/workers
# we attach them via 2 resources
# terraform plan -target aws_lb_target_group_attachment.docker_swarm_leader_attachment -var-file chaos.tfvars
resource "aws_lb_target_group_attachment" "docker_swarm_leader_attachment" {
  target_group_arn = aws_lb_target_group.docker_swarm_tg.arn
  target_id        = aws_instance.ec2_leader.id
  port             = 80
}

# now all the other EC2s
# terraform plan -target aws_lb_target_group_attachment.docker_swarm_ec2_attachments -var-file chaos.tfvars
resource "aws_lb_target_group_attachment" "docker_swarm_group_a_attachments" {
  count            = length(aws_instance.ec2_group_a)
  target_group_arn = aws_lb_target_group.docker_swarm_tg.arn
  target_id        = aws_instance.ec2_group_a[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "docker_swarm_group_b_attachments" {
  count            = length(aws_instance.ec2_group_b)
  target_group_arn = aws_lb_target_group.docker_swarm_tg.arn
  target_id        = aws_instance.ec2_group_b[count.index].id
  port             = 80
}