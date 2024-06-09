# s3-static-hosting

Create a bucket with static hosting on S3 and also create the corresponding DNS record in Route 53.

This assimes the zone exists, you CAN import it with `terraform import aws_route53_zone.main [ZONE_ID]` -- check your account for `ZONE_ID` or use the AWS command line.

## Variables

`terraform.tfvars`:

```
bucket_name       = "mycoolsite"
website_name      = "mycoolsite"
domain_name       = "domain.com"
create_s3_objects = false
```

...this will create `mycoolsite.domain.com`.

If `create_s3_objects` is `true` it'll upload a hello world file, contents are in `src/`.

It's not clear if AWS now requires the bucket name to be the same as the FQDN?  `bucket_name` and `website_name` are sort of redundant at this moment.

## Links

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
