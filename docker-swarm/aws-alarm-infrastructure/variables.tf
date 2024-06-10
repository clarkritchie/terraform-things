variable "aws_region" {
  type        = string
  description = "The AWS region to use"
  default     = "us-west-1"
}

variable "environments" {
  type = list(object({
    name              = string
    emails            = list(string)
    slack_webhook_url = string
  }))
}