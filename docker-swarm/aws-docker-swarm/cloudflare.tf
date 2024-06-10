resource "cloudflare_record" "ec2_leader_dns" {
  depends_on = [aws_eip.leader_ip] # this is a guess
  zone_id    = data.cloudflare_zones.domain.zones[0].id
  name       = var.environment
  value      = aws_instance.ec2_leader.public_ip
  type       = "A"
  ttl        = 60 # or 1 for automatic
  proxied    = false
}

resource "cloudflare_record" "ec2_group_a_dns" {
  depends_on = [aws_eip.ec2_group_a_ips] # this is a guess
  count      = var.group_a_nodes
  zone_id    = data.cloudflare_zones.domain.zones[0].id
  name       = "${var.environment}-a${count.index + 1}"
  value      = aws_instance.ec2_group_a[count.index].public_ip
  type       = "A"
  ttl        = 60
  proxied    = false
}

resource "cloudflare_record" "ec2_group_b_dns" {
  depends_on = [aws_eip.ec2_group_b_ips] # this is a guess
  count      = var.group_b_nodes
  zone_id    = data.cloudflare_zones.domain.zones[0].id
  name       = "${var.environment}-b${count.index + 1}"
  value      = aws_instance.ec2_group_b[count.index].public_ip
  type       = "A"
  ttl        = 60
  proxied    = false
}

resource "cloudflare_record" "ec2_worker_dns" {
  # not currently using EIPs for workers
  count   = var.worker_nodes
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${var.environment}-w${count.index + 1}"
  value   = aws_instance.worker[count.index].public_ip
  type    = "A"
  ttl     = 60
  proxied = false
}

# terraform plan -target cloudflare_record.host_dns -var-file chaos.tfvars
resource "cloudflare_record" "host_dns" {
  for_each = { for idx, entry in local.ip_fqdn : idx => entry }
  zone_id  = data.cloudflare_zones.domain.zones[0].id
  name     = each.value.fqdn
  type     = "A"
  proxied  = true
  ttl      = 1 # must be 1 when proxied
  value    = each.value.ip_address
}
