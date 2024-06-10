variable "aws_region" {
  type        = string
  description = "The AWS region to use"
  default     = "us-west-1"
}

variable "emails" {
  type        = list(string)
  description = "The emails to send to"
  default     = []
}


variable "create_detector" {
  type        = bool
  description = "Whether or not to create GuardDuty, only one instance is allowed for the entire account"
  default     = false
}
