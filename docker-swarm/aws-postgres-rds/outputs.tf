
output "postgres_hostname" {
  value = "${cloudflare_record.rds_dns.name}.${var.site_domain}"
}

output "master_password" {
  value     = random_password.master_password.result
  sensitive = true
}

output "cluster_endpoint" {
  value = module.postgres_serverless.cluster_endpoint
}

output "cluster_port" {
  value = module.postgres_serverless.cluster_port
}

output "db_master_username" {
  value = var.db_master_username
}