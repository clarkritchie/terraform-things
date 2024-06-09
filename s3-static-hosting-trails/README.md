# s3-static-hosting-trails

Sets up basic bucket for static hosting on S3 and creates the corresponding DNS record in Route 53.

## Variables

`terraform.tfvars`:

```
bucket_name       = "cool"
website_name      = "trcoolails"
domain_name       = "domain.com"
create_s3_objects = false
```

Will create `cool.domain.com`.  If `create_s3_objects` is `true` it'll upload a hello world file, see `src/`.

It's not clear if AWS now requires the bucket name to be the same as the FQDN?

## Links

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)