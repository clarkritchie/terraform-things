
# Important -- This should be set OUTSIDE of the .tfvars file, e.g. export TF_VAR_cloudflare_api_token="xyz"
# Do not commit this to source code
variable "cloudflare_api_token" {
  type        = string
  description = "The CloudFlare API token to use"
  default     = ""
}

# Important -- This should be set OUTSIDE of the .tfvars file, e.g. export TF_VAR_cloudflare_account_id="xyz"
variable "cloudflare_account_id" {
  type        = string
  description = "The CloudFlare Account ID to use"
  default     = "84c1f4bed1c7066171175fc2db1de0ff"
}

# Important -- This should be set OUTSIDE of the .tfvars file, e.g. export TF_VAR_dockerhub_username="xyz"
# Do not commit this to source code
variable "dockerhub_username" {
  type        = string
  description = "Username to authenticate with Docker Hub for container pulls"
  default     = ""
}

# Important -- This should be set OUTSIDE of the .tfvars file, e.g. export TF_VAR_dockerhub_token="xyz"
# Do not commit this to source code
variable "dockerhub_token" {
  type        = string
  description = "Token to authenticate with Docker Hub for container pulls"
  default     = ""
}

# The CloudFlare token must be scoped to have DNS write in this zone
variable "site_domain" {
  type        = string
  description = "The DNZ zone to use"
  default     = "mycompany.app"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to use"
  default     = "us-west-1"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"

}

# Note -- this cidr_block is also referenced in default_security_group_ingress
variable "cidr_block" {
  type        = string
  description = "The CIDR block to use"
  default     = ""
}

variable "public_subnets" {
  type        = list(string)
  description = "The CIDR blocks to use for the public subnets"
  default     = []
}

variable "database_subnets" {
  type        = list(string)
  description = "The CIDR blocks to use for the database subnets"
  default     = []
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "The CIDR blocks to use for the ElastiCache subnets"
  default     = []
}

variable "private_subnets" {
  type        = list(string)
  description = "The CIDR blocks to use for the private subnets"
  default     = []
}

# Managers, group A
variable "group_a_nodes" {
  type        = number
  description = "The number of EC2 instances to launch in Manager Group A"
  default     = 1
}

# Managers, group B
variable "group_b_nodes" {
  type        = number
  description = "The number of EC2 instances to launch in Manager Group B"
  default     = 1
}

# Workers
variable "worker_nodes" {
  type        = number
  description = "The number of EC2 instances to launch in Worker Group B"
  default     = 0
}

variable "key_name" {
  type        = string
  description = "The name of the SSH key to use for the EC2 instance (must already exist)"
}

variable "default_security_group_ingress" {
  description = "List of maps of ingress rules to set on the default security group"
  type        = list(map(string))
  default = [
    {
      cidr_blocks = "10.0.0.0/8"
      description = "Allow all from the local network"
      from_port   = 0
      protocol    = "-1"
      self        = false
      to_port     = 0
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all HTTPS from the internet"
      from_port   = 443
      protocol    = "6"
      self        = false
      to_port     = 443
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all HTTP from the internet"
      from_port   = 80
      protocol    = "6"
      self        = false
      to_port     = 80
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all SSH from the internet"
      from_port   = 22
      protocol    = "6"
      self        = false
      to_port     = 22
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all ephemeral ports from the internet"
      from_port   = 32768
      protocol    = "6"
      self        = false
      to_port     = 60999
    }
  ]
}

variable "default_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default = [
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all"
      from_port   = 0
      protocol    = "-1"
      self        = false
      to_port     = 0
    }
  ]
}

variable "ami" {
  type        = string
  description = "AMI to use"
  default     = "ami-0ce2cb35386fc22e9" # Ubuntu 22.04
}

variable "host_names" {
  type        = list(string)
  description = "List of CNAMEs to alias to the LBs"
  default     = []
}

# See this link for values
# https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
variable "elb_account_id" {
  type        = string
  description = "AWS account for Elastic Load Balancing for this region"
  default     = "027434742980"
}

variable "instance_type" {
  type        = string
  description = "Instance type to use"
  default     = "t2.medium"
}

# it's unclear if this works as advertised
variable "user_data_replace_on_change" {
  type        = bool
  description = "Triggers a destroy and recreate when set to true and when user data changes"
  default     = false
}

variable "alarm_arn" {
  type        = string
  description = "ARN to use for alarm notifications, aka alerts"
  default     = ""
}