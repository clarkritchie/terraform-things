# AWS Guard Duty

This is VERY quick and dirty.  The aboslute bare minimum to satisfy Vanta and it's SOC-2 checks.

For a region, it creates an SNS topic and email subscriptions.

Use Terraform workspaces!  e.g.

```
terraform workspace new us-west-1
terraform workspace new eu-west-1
terraform workspace new us-west-2
terraform workspace new us-east-1

terraform workspace select us-west-1
terraform apply -var-file=us-west-1.tfvars

terraform workspace select eu-west-1
terraform apply -var-file=eu-west-1.tfvars

terraform workspace select us-west-2
terraform apply -var-file=us-west-2.tfvars


terraform workspace select us-east-1
terraform apply -var-file=us-east-1.tfvars
```

Might want to do this:

```
#!/usr/bin/env bash

ACTION=${1:-plan}

REGIONS=(
    us-west-1
    us-east-1
    eu-west-1
    us-west-2
)
for REGION in "${REGIONS[@]}"
do
    terraform workspace select ${REGION}
    terraform ${ACTION} -var-file ${REGION}.tfvars
done
```

## Links

- https://github.com/trussworks/terraform-aws-guardduty-notifications/blob/main/main.tf