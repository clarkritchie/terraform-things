terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
  }

  required_version = ">= 1.4.6"
}

provider "aws" {
  region = var.aws_region
}
