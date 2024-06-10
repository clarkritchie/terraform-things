data "terraform_remote_state" "aws_docker_swarm" {
  backend = "s3"
  config = {
    bucket = "terraform-state-backend"
    key    = "env:/${var.environment}/aws-docker-swarm.tfstate"
    region = "us-west-2"
  }
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.site_domain
  }
}

data "aws_caller_identity" "current" {}