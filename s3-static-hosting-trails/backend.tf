terraform {
  backend "s3" {
    bucket         = "terraform-state-clarkritchie"
    key            = "s3-static-hosting-trails.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform_state"
  }
}