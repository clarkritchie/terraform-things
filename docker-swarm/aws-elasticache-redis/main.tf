# terraform apply -target module.elasticache_sg -var-file chaos.tfvars
module "elasticache_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "${var.environment}-elasticache-sg"
  description = "ElastiCache in the ${var.environment} environment"
  vpc_id      = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id
}

# terraform apply -target aws_security_group_rule.elasticache_public_ingress -var-file chaos.tfvars
resource "aws_security_group_rule" "elasticache_public_ingress" {
  description       = "ElastiCache ingress, allow Redis traffic to ElastiCache subnet from Public subnet"
  type              = "ingress"
  security_group_id = module.elasticache_sg.security_group_id
  from_port         = 6379
  to_port           = 6379
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"
}

# terraform apply -target aws_security_group_rule.elasticache_self_ingress -var-file chaos.tfvars
resource "aws_security_group_rule" "elasticache_self_ingress" {
  description       = "ElastiCache ingress, allow Redis traffic to ElastiCache subnet from itself"
  type              = "ingress"
  security_group_id = module.elasticache_sg.security_group_id
  from_port         = 6379
  to_port           = 6379
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_elasticache_cidrs
  protocol          = "tcp"
}

# terraform apply -target aws_security_group_rule.elasticache_public_egress -var-file chaos.tfvars
resource "aws_security_group_rule" "elasticache_public_egress" {
  description       = "ElastiCache egress, allow Redis traffic to Public subnet from ElastiCache subnet"
  type              = "egress"
  security_group_id = module.elasticache_sg.security_group_id
  from_port         = 6379
  to_port           = 6379
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"
}

# terraform apply -target aws_security_group_rule.elasticache_self_egress -var-file chaos.tfvars
resource "aws_security_group_rule" "elasticache_self_egress" {
  description       = "ElastiCache egress, allow Redis traffic to itself subnet from ElastiCache subnet"
  type              = "egress"
  security_group_id = module.elasticache_sg.security_group_id
  from_port         = 6379
  to_port           = 6379
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_elasticache_cidrs
  protocol          = "tcp"
}

# terraform apply -target module.elasticache_primary_db -var-file chaos.tfvars
module "elasticache_redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "1.2.0"
  vpc_id  = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id

  description    = "ElastiCache for use in the ${var.environment} environment"
  family         = var.family
  engine_version = var.engine_version
  instance_type  = var.instance_type

  # When the cluster has the 'Encryption in-transit' option set, the database
  # has to be accessed through SSL,which redis-cli does not do, this settings
  # also reverts to true if auth_token is set
  transit_encryption_enabled = false # true to require SSL
  at_rest_encryption_enabled = true
  # TODO
  cluster_mode_enabled       = var.cluster_mode_enabled
  automatic_failover_enabled = var.automatic_failover_enabled # these are defaulting to false
  multi_az_enabled           = var.multi_az_enabled           # these are defaulting to false
  availability_zones         = var.azs                        # TODO do we need this?
  replication_group_id       = var.environment

  create_security_group         = false
  associated_security_group_ids = [module.elasticache_sg.security_group_id]

  # this is a guess to get around theis error in the console logs:
  # WARNING: Your Redis instance will evict Sidekiq data under heavy load.
  # The 'noeviction' maxmemory policy is recommended (current policy: 'volatile-lru').
  # See: https://github.com/sidekiq/sidekiq/wiki/Using-Redis#memory
  # if create_parameter_group is false, it uses default.redis7
  create_parameter_group      = true
  parameter_group_name        = "${var.environment}-elasticache-parameter-group"
  parameter_group_description = "ElastiCache parameter group for the ${var.environment} environment"
  parameter = [
    {
      name  = "maxmemory-policy"
      value = "noeviction"
    }
  ]
  subnets                       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_elasticache_subnets
  elasticache_subnet_group_name = data.terraform_remote_state.aws_docker_swarm.outputs.elasticache_subnet_group_name

  tags = {
    Environment = var.environment
  }
}