variable "repos" { type = list(string) }

resource "github_branch_protection" "main" {
  for_each = toset(var.repos)
  repository = each.key
  branch     = "main"

  required_status_checks {
    strict = true
    contexts = ["verify-signatures", "dependency-scan"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 2
    require_code_owner_reviews      = true
  }

  enforce_admins = false
  allow_force_push = false
}
