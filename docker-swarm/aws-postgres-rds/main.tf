# terraform apply -target module.postgres_db_sg -var-file chaos.tfvars
module "postgres_db_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.1.0"
  name        = "${var.environment}-postgresql-sg"
  description = "PostgreSQL in the ${var.environment} environment"
  vpc_id      = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id
  tags        = local.tags
}

# terraform apply -target aws_security_group_rule.postgres_ingress -var-file chaos.tfvars
resource "aws_security_group_rule" "postgres_ingress" {
  description       = "PostgreSQL ingress, from public to database subnets"
  type              = "ingress"
  security_group_id = module.postgres_db_sg.security_group_id
  from_port         = 5432
  to_port           = 5432
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"
}

# terraform apply -target aws_security_group_rule.postgres_egress -var-file chaos.tfvars
resource "aws_security_group_rule" "postgres_egress" {
  description       = "PostgreSQL egress, from database to public subnets"
  type              = "egress"
  security_group_id = module.postgres_db_sg.security_group_id
  from_port         = 5432
  to_port           = 5432
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"
}

# terraform apply -target random_password.password -var-file chaos.tfvars
resource "random_password" "master_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # these are the permitted special characters
}

resource "aws_ssm_parameter" "master_password_parameter" {
  name        = "/${var.environment}/database/postgres/${var.db_master_username}/password"
  description = "Terraform generated password for Postgres user ${var.db_master_username} in ${var.environment}"
  type        = "SecureString"
  value       = random_password.master_password.result
  tags        = local.tags
}

# reference:
# - https://github.com/terraform-aws-modules/terraform-aws-rds-aurora/blob/v9.0.0/examples/serverless/main.tf
module "postgres_serverless" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.1.0"

  name                        = "${var.environment}-postgresql-serverless-v2"
  engine                      = var.engine
  engine_mode                 = "provisioned"
  engine_version              = var.engine_version
  storage_encrypted           = true
  master_username             = var.db_master_username
  manage_master_user_password = false
  master_password             = random_password.master_password.result
  delete_automated_backups    = var.delete_automated_backups
  deletion_protection         = var.deletion_protection
  backup_retention_period     = var.backup_retention_period

  vpc_id               = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id
  db_subnet_group_name = data.terraform_remote_state.aws_docker_swarm.outputs.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
    }
  }

  monitoring_interval    = var.enhanced_monitoring ? 60 : 0
  create_monitoring_role = var.enhanced_monitoring ? true : false
  iam_role_name          = var.enhanced_monitoring ? "${var.environment}-postgresql-enhanced-monitoring" : null
  iam_role_description   = var.enhanced_monitoring ? "Enhanced monitoring for Postgres RDS in ${var.environment}" : null

  apply_immediately            = var.apply_immediately
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = "${var.environment}-postgresql-final"
  performance_insights_enabled = var.performance_insights_enabled

  # https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_ServerlessV2ScalingConfiguration.html
  serverlessv2_scaling_configuration = {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  instance_class = "db.serverless"
  instances      = local.instances_map

  db_parameter_group_name = aws_db_parameter_group.default.name

  tags = local.tags
}

# IAM role to allow enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.environment}-postgres-rds-enhanced-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# this is a guess, creating database thigs ith the postgres provider seems to
# fail, probably because the database server isn't "ready" for connections
# trying to insert a pause to see if that helps
# this is really only an issue when a new env comes up from scratch
# also, this may or may not be correct Terraform syntax
resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
}

resource "null_resource" "delay" {
  depends_on = [time_sleep.wait_30_seconds]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "aws_db_parameter_group" "default" {
  name = "${var.environment}-aurora-postgresql14"
  # find the valid families with:  aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily"
  family = "aurora-postgresql14"
  tags   = local.tags

  parameter {
    name  = "client_min_messages"
    value = "notice" # debug5, debug4 debug3, debug2, debug1,log, notice, warning, error
  }

  lifecycle {
    create_before_destroy = true
  }
}