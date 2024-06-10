terraform {
  backend "s3" {
    # edit all of this
    bucket         = "terraform-state-backend"
    key            = "aws-guardduty.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform_state"
  }
}