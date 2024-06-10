# Docker Swarm

This is a past project to stand up a Docker Swarm cluster using EC2s on AWS.

- `aws-alarm-infrastructure` - Very simple SNS setup to send CloudWatch alarm notifications by email and Slack, is configurable by environment
- `aws-docker-swarm` -- This is the "base" layer and creates a VPC, subnets and launches a variable number of EC2s that bootstrap themselves with Docker Swarm
- `aws-elasticache-redis` -- Redis layer, builds on `aws-docker-swarm` (i.e. uses outputs)
- `aws-postgres-rds` -- Postgres Serverless V2, builds on `aws-docker-swarm`
- `aws-mysql-rds` -- Essentially identical to `aws-postgres-rds` but for MySQL Serverless V2, builds on `aws-docker-swarm`, this may be incomplete as MySQL was deprecated for Postgres while this was under development

Most of these create DNS records in CloudFlare, so the Terraform expects your CloudFlare API token to be in the env, e.g. `TF_VAR_cloudflare_api_token` -- `see variables.tf`.