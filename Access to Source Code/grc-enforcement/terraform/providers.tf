terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 4.0.0"
    }
  }
}
provider "github" {
  token = var.github_token
  owner = var.github_org
}
