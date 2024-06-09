variable "aws_region" {
  type        = string
  description = "The AWS region to use"
  default     = "us-west-2"
}

variable "bucket_name" {
  type        = string
  description = "Bucket name"
}

variable "domain_name" {
  type        = string
  description = "The website's fully qualified domain name"
}

variable "website_name" {
  type        = string
  description = "The site's hostname -- will be concatenated with the domain_name"
}

variable "create_s3_objects" {
  type        = bool
  description = "Uploads a basic website when true"
  default     = false
}