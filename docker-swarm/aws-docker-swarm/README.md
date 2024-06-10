# AWS Docker Swarm

Creates:
- VPC
- Public, Private and Database subnets across availability zones
- Route tables
- NAT Gateway
- Load Balancer
- Launches N EC2s and creates DNS names, e.g. `dev-0.mycompany.app`, `dev-1.mycompany.app`, etc.
- Installs Docker Swarm, joins them together

## Shared Configs

Shared configs, CI/CD outputs, etc. all live in an S3 bucket named `docker-swarm-[env]` and these are copied down on startup.

## SSH

If your public key is in the user data script, you should be able to:

```
ssh ubuntu@[env]-1.mycompany.app
```



Use Terraform workspaces!  e.g.

```
terraform workspace new test
terraform workspace new dev
terraform workspace new staging
```

```
./run.sh
./run.sh dev apply
```

## Misc

May need to clear the DNS cache on OS/X:

```
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder1
```

May need to periodically do something like this:

```
ssh-keygen -R dev-1.mycompany.app
ssh-keygen -R dev-2.mycompany.app
ssh-keygen -R dev-3.mycompany.app
```

Or this:

```
#!/usr/bin/env bash

ENV=${1:-test}

for N in 0 1 2
do
	ssh-keygen -R ${ENV}-${N}.mycompany.app
done
```

## Links

- [VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [EC2](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws)
- [ELB](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb)
- [EC2 Launch Template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)

## Apple Silicon Gotchas

```Provider registry.terraform.io/hashicorp/template v2.2.0 does not have a package available for your current platform, darwin_arm64.
```
```
brew install kreuzwerker/taps/m1-terraform-provider-helper
m1-terraform-provider-helper activate
m1-terraform-provider-helper install  hashicorp/template --version 2.2.0
```

Then re-run `terraform init`

- [Link](https://medium.com/@immanoj42/terraform-template-v2-2-0-does-not-have-a-package-available-mac-m1-m2-2b12c6281ea)