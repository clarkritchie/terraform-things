# AWS Postres RDS

Uses Terraform workspaces.

Uses `outputs` from the `aws-docker-swarm` Terraform.

> Unlike other RDS resources that support replication, with Amazon Aurora you do not designate a primary and subsequent replicas. Instead, you simply add RDS Instances and Aurora manages the replication. You can use the count meta-parameter to make multiple instances and join them all to the same RDS Cluster, or you may specify different Cluster Instance resources with various instance_class sizes.

## Linting

- `tflint` -- see `.tflint.hcl`

## Misc

The exact values for some of these variables secan bem a bit cryptic and hard to figure out what AWS will accept.  See also the link for DescribeDBEngineVersions below.

To list all of the available parameter group families for a DB engine, use the following command:

```aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily" --engine <engine>```

For example, to list all of the available parameter group families for the Aurora PostgreSQL DB engine, use the following command:

```aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily" --engine aurora-postgresql```

Check to see if a db instance type is valid or not:

```aws rds describe-orderable-db-instance-options --engine aurora-postgresql --db-instance-class db.r5.large --region us-west-1```

## Serverless Databases

- [How Aurora Serverless v2 works](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html)
- [Understanding Amazon Aurora Serverless Pricing](https://www.cloudthread.io/blog/understanding-amazon-aurora-serverless-pricing#:~:text=Aurora%20Capacity%20Units,allocated%20to%20a%20database%20instance.)

## Links

- [RDS Aurora](https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest) -- this is RDS Aurora, not regular RDS
- [DescribeDBEngineVersions](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBEngineVersions.html)]
- [DBInstanceClass](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html)
- [Postgres Provider](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs)