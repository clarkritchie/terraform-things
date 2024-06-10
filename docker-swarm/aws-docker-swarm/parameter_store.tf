# The overwrite attribute has been deprecated. Existing parameters should be explicitly
# imported rather than relying on the "import on create" behavior previously enabled by
# setting overwrite = true. In a future major version the overwrite attribute will be
# removed and attempting to create a parameter that already exists will fail.

# terraform import -var-file chaos.tfvars 'aws_ssm_parameter.dockerhub_username' dockerhub_username
# terraform plan -target aws_ssm_parameter.dockerhub_username -var-file chaos.tfvars
resource "aws_ssm_parameter" "dockerhub_username" {
  name  = "/${var.environment}/dockerhub/username"
  type  = "SecureString"
  value = var.dockerhub_username
  tags  = local.tags
}

# terraform plan -target aws_ssm_parameter.dockerhub_token -var-file chaos.tfvars
resource "aws_ssm_parameter" "dockerhub_token" {
  name  = "/${var.environment}/dockerhub/token"
  type  = "SecureString"
  value = var.dockerhub_token
  tags  = local.tags
}

resource "aws_ssm_parameter" "countwatch_agent_config" {
  name        = "/${var.environment}/amazon-cloudwatch-linux"
  description = "Coudwatch Agent config for Ubuntu"
  type        = "String"
  value       = file("${path.module}/etc/cloudwatch-agent.json")
  tags        = local.tags
}
