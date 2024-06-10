locals {
  tags = {
    Terraform   = "True"
    Environment = var.environment
  }

  yass_db_name     = "yass_db"
  yass_db_username = "yass"

  milestones_db_name     = "mycompany_milestones"
  milestones_db_username = "milestones"

  # this is a little non-sequitor, but...
  instances_map_tmp = {
    1  = {}
    ro = var.reader_instance ? {} : null
  }

  # ...produces this (if reader_instance is false)
  # {
  #   "1" = {}
  # }
  #
  # or this (if reader_instance is true)
  # {
  #   "1" = {}
  #   "ro" = {}
  # }
  instances_map = {
    for key, value in local.instances_map_tmp :
    key => value if value != null
  }
}