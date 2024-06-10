# Docker Swarm

This is a past project to stand up a Docker Swarm cluster using EC2s on AWS.

- `aws-alarm-infrastructure` - Very simple SNS setup to send alarm notifications by email
- `aws-docker-swarm` -- This is the "base" layer and creates a VPC, subnets and launches a variable number of EC2s that bootstrap themselves with Docker Swarm
- `aws-elasticache-redis` -- Redis layer, builds on `aws-docker-swarm` (i.e. uses outputs)
- `aws-postgres-rds` -- Postgres Serverless V2, builds on `aws-docker-swarm`
- `aws-mysql-rds` -- Essentially identical to `aws-postgres-rds` but for MySQL Serverless V2, builds on `aws-docker-swarm`
