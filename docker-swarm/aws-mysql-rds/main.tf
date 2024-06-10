# terraform apply -target module.mysql_db_sg -var-file chaos.tfvars
module "mysql_db_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.1.0"
  name        = "${var.environment}-mysql-sg"
  description = "MySQL in the ${var.environment} environment"
  vpc_id      = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id
  tags        = local.tags
}

# terraform apply -target aws_security_group_rule.mysql_ingress -var-file chaos.tfvars
resource "aws_security_group_rule" "mysql_ingress" {
  description       = "MySQL ingress, from public to database subnets"
  type              = "ingress"
  security_group_id = module.mysql_db_sg.security_group_id
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"
}

# terraform apply -target aws_security_group_rule.mysql_egress -var-file chaos.tfvars
resource "aws_security_group_rule" "mysql_egress" {
  description       = "MySQL egress, from database to public subnets"
  type              = "egress"
  security_group_id = module.mysql_db_sg.security_group_id
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
  protocol          = "tcp"

}

# terraform apply -target random_password.master_password -var-file chaos.tfvars
resource "random_password" "master_password" {
  length           = 20
  special          = true
  override_special = "*-_=" # these are the permitted special characters
}

# terraform apply -target ranaws_ssm_parameterdom_password.master_password_parameter -var-file chaos.tfvars
resource "aws_ssm_parameter" "master_password_parameter" {
  name        = "/${var.environment}/database/mysql/${var.db_master_username}/password"
  description = "Terraform generated password for MySQL user ${var.db_master_username} in ${var.environment}"
  type        = "SecureString"
  value       = random_password.master_password.result
  tags        = local.tags
}

# reference:
# - https://github.com/terraform-aws-modules/terraform-aws-rds-aurora/blob/v9.0.0/examples/serverless/main.tf
#
# See the value of master_password
# - terraform show -json | jq '.' | grep master_password
#
module "mysql_serverless" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.0.0"

  name                        = "${var.environment}-mysql-serverless-v2"
  engine                      = var.engine
  engine_mode                 = "provisioned"
  engine_version              = var.engine_version
  storage_encrypted           = true
  master_username             = var.db_master_username
  manage_master_user_password = false
  master_password             = random_password.master_password.result
  delete_automated_backups    = var.delete_automated_backups
  deletion_protection         = var.deletion_protection

  vpc_id               = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_id
  db_subnet_group_name = data.terraform_remote_state.aws_docker_swarm.outputs.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = data.terraform_remote_state.aws_docker_swarm.outputs.vpc_public_cidrs
    }
  }

  monitoring_interval = var.enhanced_monitoring ? 60 : 0

  apply_immediately   = var.apply_immediately
  skip_final_snapshot = var.skip_final_snapshot

  # https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_ServerlessV2ScalingConfiguration.html
  serverlessv2_scaling_configuration = {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  instance_class = "db.serverless"
  instances      = local.instances_map

  tags = local.tags
}
# IAM role to allow enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.environment}-mysql-rds-enhanced-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}