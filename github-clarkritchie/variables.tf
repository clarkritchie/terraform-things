# Define this as an env var, e.g. export TF_VAR_GITHUB_TOKEN="xxx"
variable "GITHUB_TOKEN" {
  type        = string
  description = "Personal access tokens (PATs) for authentication to GitHub."
}

variable "repositories" {
  type = list(object({
    name          = string
    description   = string
    visibility    = string
    homepage_url  = optional(string)
    include_pages = optional(bool, false)
    pages_cname   = optional(string)
    has_projects  = optional(bool, false)
    dependabot    = optional(bool, false)
  }))
}