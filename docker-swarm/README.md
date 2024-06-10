# Docker Swarm

This is a past project to stand up Docker Swarm cluster on AWS.

- `aws-alarm-infrastructure` - Very simple SNS setup to send alarm notifications by email.
- `aws-docker-swarm` -- This is the "base" layer and creates a VPC, subnets and launches a variable number of EC2s that bootstrap themselves with Docker Swarm.
- `aws-elasticache-redis` -- Redis layer, uses outputs from the base layer.
- `aws-postgres-rds` -- Postgres Serverless V2.
- `aws-mysql-rds` -- Essentially identical to `aws-postgres-rds` but for MySQL Serverless V2.