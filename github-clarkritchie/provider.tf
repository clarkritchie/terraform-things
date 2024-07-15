terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.2.3"
    }
  }
}

provider "github" {
  owner = "clarkritchie"
  token = var.GITHUB_TOKEN
}
