# github-clarkritchie

An ultra stripped down version of a past Terraform project for managing GitHub repos, and so on.

## Usage

Create a PAT with the permissions you need, then:
```
export TF_VAR_GITHUB_TOKEN="github_pat_xxx"
```

Import existing repo then do a targeted plan and apply, e.g.

```
terraform init
terraform import 'github_repository.repo["terraform-things"]
terraform plan -target 'github_repository.repo["terraform-things"]'
terraform apply -target 'github_repository.repo["terraform-things"]'
```