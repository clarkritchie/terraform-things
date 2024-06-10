variable "aws_region" {
  type        = string
  description = "The AWS region to use"
  default     = "us-west-1"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "cloudflare_api_token" {
  type        = string
  description = "The CloudFlare API token to use"
  default     = ""
}

# The CloudFlare token must be scoped to have DNS write in this zone
variable "site_domain" {
  type        = string
  description = "The DNZ zone to use"
  default     = "mycompany.app"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"
}

variable "engine_version" {
  type        = string
  description = "Redis version to use"
  default     = "7.1"
}

variable "family" {
  type        = string
  description = "Redis family"
  default     = "redis7"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "cache.t2.micro"
}

variable "cluster_mode_enabled" {
  type        = bool
  description = "Flag to enable/disable creation of a native redis cluster"
  default     = false
}

variable "automatic_failover_enabled" {
  type        = bool
  description = "Automatic failover (not available for T1/T2 instances)"
  default     = false
}

variable "multi_az_enabled" {
  type        = bool
  description = "Multi AZ -- Automatic Failover must also be enabled.  If Cluster Mode is enabled, Multi AZ is on by default, and this setting is ignored"
  default     = false
}