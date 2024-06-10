output "redis_hostname" {
  value = "${cloudflare_record.redis_dns.name}.${var.site_domain}"
}