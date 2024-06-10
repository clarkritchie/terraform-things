# https://daringway.com/how-to-select-one-random-aws-subnet-in-terraform/
resource "random_id" "index" {
  byte_length = 2
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"

  name                        = "${var.environment}-vpc"
  default_security_group_name = "${var.environment}-vpc-sg"
  default_security_group_tags = {
    Environment = var.environment
  }
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress
  cidr                           = var.cidr_block
  azs                            = var.azs

  # this needs a destination ARN, etc.
  # enable_flow_log                = true

  # One NAT Gateway per subnet is the default behavior, e.g.
  # enable_nat_gateway     = true
  # single_nat_gateway     = false
  # one_nat_gateway_per_az = false
  enable_nat_gateway = false

  # applied to all resources
  tags = local.tags

  public_subnets = var.public_subnets
  public_subnet_tags = {
    Type = "public"
  }
  public_route_table_tags = {
    Type = "public"
  }

  private_subnets = var.private_subnets
  private_subnet_tags = {
    Type = "private"
  }
  private_route_table_tags = {
    Type        = "private"
    Environment = var.environment
  }

  database_subnets = var.database_subnets
  # database_subnet_group_name = "${var.environment}-db" # TODO enable this
  database_subnet_tags = {
    Type = "database"
  }
  database_route_table_tags = {
    Type = "database"
  }

  elasticache_subnets = var.elasticache_subnets
  # elasticache_subnet_group_name = "${var.environment}-elasticache" # TODO enable this
  # elasticache_subnet_tags = {
  #   Type = "elasticache"
  # }
  elasticache_route_table_tags = {
    Type = "elasticache"
  }
}