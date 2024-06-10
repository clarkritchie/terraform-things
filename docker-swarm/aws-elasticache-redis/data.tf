data "terraform_remote_state" "aws_docker_swarm" {
  backend = "s3"
  config = {
    bucket = "terraform-state-backend"
    key    = "env:/${var.environment}/aws-docker-swarm.tfstate"
    region = "us-west-2"
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.site_domain
  }
}