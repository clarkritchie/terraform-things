# import existing into state as such:
# terraform import 'github_repository.repo["some-repo-name"]' some-repo-name
#
# Note on zsh globbing:  https://discuss.hashicorp.com/t/import-resource-not-working-zsh-terminal/48776/3
#
resource "github_repository" "repo" {
  for_each                    = { for r in var.repositories : r.name => r }
  name                        = each.key
  description                 = each.value.description
  visibility                  = each.value.visibility
  auto_init                   = true
  homepage_url                = each.value.homepage_url
  merge_commit_message        = "PR_TITLE"
  merge_commit_title          = "MERGE_MESSAGE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  has_projects                = each.value.has_projects

  dynamic "pages" {
    for_each = each.value.include_pages ? [1] : []
    content {
      source {
        branch = "main"
        path   = "/"
      }
      build_type = "legacy"
      cname      = each.value.pages_cname
    }
  }

  vulnerability_alerts = true
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}
