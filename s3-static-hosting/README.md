# s3-static-hosting

Create a bucket with static hosting on S3 and also create the corresponding DNS record in Route 53.

This assumes your zone exists in Riute 53, after `terraform init` you can import it with `terraform import aws_route53_zone.main [ZONE_ID]` -- check your account for `ZONE_ID` or use the AWS command line.

## Variables

`terraform.tfvars`:

```
bucket_name       = "mycoolsite"
website_name      = "mycoolsite"
domain_name       = "domain.com"
create_s3_objects = false
```

...this will create a bucket and corresponding DNS record for `http://mycoolsite.domain.com` -- note that is http not https.

If `create_s3_objects` is `true` it'll upload a simple hello world file, the contents for that are in `src/`.

TODO It's not clear if AWS maybe now requires the bucket name to be the same as the FQDN?  This seems new ([AWS docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/troubleshooting-s3-bucket-website-hosting.html)).  `bucket_name` and `website_name` are sort of redundant at this moment.

## Links

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
