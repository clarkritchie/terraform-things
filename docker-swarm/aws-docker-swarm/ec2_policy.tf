# Create the role, which is attached to the EC2
resource "aws_iam_role" "docker_swarm_ec2_role" {
  name               = "${var.environment}-docker-swarm-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.tags
}

# Create the policy for what the EC2 is allowed to do
resource "aws_iam_policy" "docker_swarm_ec2_policy" {
  name        = "${var.environment}-docker-swarm-ec2-policy"
  description = "EC2 instance policy for Docker Swarm in ${var.environment}"
  policy      = data.aws_iam_policy_document.ec2_policy.json
  tags        = local.tags
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.docker_swarm_ec2_role.name
  policy_arn = aws_iam_policy.docker_swarm_ec2_policy.arn
}

# Create an EC2 instance profile that's attached to the role
# terraform plan -target aws_iam_instance_profile.ec2_profile -var-file chaos.tfvars
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-docker-swarm-ec2-instance-profile"
  role = aws_iam_role.docker_swarm_ec2_role.name
  tags = local.tags
}