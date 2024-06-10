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

variable "engine" {
  type        = string
  description = "Database engine to use"
  default     = "aurora-postgresql"
}

variable "engine_version" {
  type        = string
  description = "Postgres version to use"
  default     = "14.10"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skips taking a final snapshot on termination"
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately"
  default     = false
}

# Database capacity is measured in Aurora Capacity Units (ACUs)
# 1 ACU provides 2 GiB of memory and corresponding compute and networking
variable "min_capacity" {
  type        = number
  description = "Serverless ACU (minimum)"
  default     = 0.5
}

variable "max_capacity" {
  type        = number
  description = "Serverless ACU (maximum)"
  default     = 1
}

variable "reader_instance" {
  type        = bool
  description = "When true it creates a read replica"
  default     = false
}

variable "enhanced_monitoring" {
  type        = bool
  description = "When true, enabled enhanced monitoring"
  default     = false
}

variable "db_master_username" {
  type        = string
  description = "Master user for the database"
  default     = "mycompany_root" # some named are restricted, dashes are not allowed
}

variable "delete_automated_backups" {
  type        = bool
  description = "When true, automated backups are deleted upon termination"
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "When true, deletion protection is disabled"
  default     = true
}

variable "alarm_arn" {
  type        = string
  description = "ARN to use for alarm notifications, aka alerts"
  default     = ""
}

variable "backup_retention_period" {
  type        = number
  description = "How many days to keep backups for"
  default     = 14
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable RDS Performance Insights"
  default     = false
}

variable "alarm_actions_enabled" {
  type        = bool
  description = "Global kill switch for alarm actions"
  default     = true
}
