resource "cloudflare_record" "redis_dns" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.environment}-cache"
  value   = module.elasticache_redis.endpoint
  type    = "CNAME"
  ttl     = 1
  proxied = false
}