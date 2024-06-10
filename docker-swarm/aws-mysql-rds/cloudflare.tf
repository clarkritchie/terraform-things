resource "cloudflare_record" "rds_dns" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.environment}-my-db"
  value   = module.mysql_serverless.cluster_endpoint
  type    = "CNAME"
  ttl     = 1
  proxied = false
}