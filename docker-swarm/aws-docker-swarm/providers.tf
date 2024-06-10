terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.25.0"
    }
  }

  required_version = ">= 1.6.6"
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}