terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.16.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }

  required_version = ">= 1.6.6"
}

provider "aws" {
  region = var.aws_region
}