terraform {
  backend "s3" {
    bucket         = "terraform-state-clarkritchie"
    key            = "github-clarkritchie.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform_state"
  }
}