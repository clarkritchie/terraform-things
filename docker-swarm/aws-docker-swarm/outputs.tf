# for debugging, it can be useful to return these outputs to the console

output "public_subnet_ids_list" {
  value = local.public_subnet_ids_list
}

# output "fully_qualified_host_names" {
#   value = local.fully_qualified_host_names
# }

output "ip_fqdn" {
  value = local.ip_fqdn
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_public_cidrs" {
  value = var.public_subnets # bad choice of a varialbe name!
}

output "vpc_database_subnets" {
  value = module.vpc.database_subnets
}

output "vpc_database_cidrs" {
  value = module.vpc.database_subnets # bad choice of a variable name!
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group # e.g. test-vpc-db-us-west-1a
}

output "vpc_elasticache_subnets" {
  value = module.vpc.elasticache_subnets
}

output "vpc_elasticache_cidrs" {
  value = var.elasticache_subnets # bad choice of a variable name!
}

output "elasticache_subnet_group_name" {
  value = module.vpc.elasticache_subnet_group_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "leader_public_dns" {
  value = aws_instance.ec2_leader.public_dns
}

output "cidr_block" {
  value = var.cidr_block
}