# import existing zone:
#   terraform import aws_route53_zone.main [hosted-zone-id]
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = {
    Name        = var.domain_name
    description = var.domain_name
  }
  comment = var.domain_name
}

resource "aws_route53_record" "a-record" {
  zone_id = aws_route53_zone.main.zone_id
  # The name of the bucket is the same as the name of the record that you're creating.
  name    = "${var.bucket_name}.${var.domain_name}"
  type = "A"

  alias {
    name = data.aws_s3_bucket.bucket.website_domain
    # The zone_id isn't your zone, it's for the bucket, you can find it on this table:
    # https://docs.aws.amazon.com/general/latest/gr/s3.html#s3_website_region_endpoints
    # or get it from the data element, e.g.
    zone_id                = data.aws_s3_bucket.bucket.hosted_zone_id
    evaluate_target_health = false
  }
}