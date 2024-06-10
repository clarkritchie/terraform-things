data "aws_caller_identity" "current" {}

data "cloudflare_zones" "domain" {
  filter {
    name = var.site_domain
  }
}

data "aws_iam_policy_document" "ec2_policy" {
  #
  # SSM
  #
  statement {
    sid = "DockerSwarmSSM"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
      "ssm:DeleteParameter"
    ]
    resources = [
      # this is the namespace for the cloudwatch agent config
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/amazon-cloudwatch-linux*",
      # this is the namespace for the ubuntu user password
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/i-*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/token/manager",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/token/manager/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/token/worker",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/token/worker/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/ip/leader",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/swarm/ip/leader/*",
      # these 2 must be populated manually
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/dockerhub/token",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/dockerhub/token/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/dockerhub/username",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/dockerhub/username/*",
    ]
    effect = "Allow"
  }

  # this is a duplicate of the AWS managed policy named CloudWatchAgentServerPolicy
  statement {
    sid = "CloudWatchAgentServerPolicy"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = [
      # this is a guess
      # "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
      # "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      "*"

    ]
    effect = "Allow"
  }

  # TODO it's not really clear why this is needed
  # syslog was reporting:
  # Jan 22 19:12:33 chaos amazon-ssm-agent.amazon-ssm-agent[396]: 2024-01-22 19:12:33 WARN EC2RoleProvider Failed to connect to Systems Manager with instance profile role credentials. Err: retrieved credentials failed to report to ssm. RequestId: 74219e82-9bac-4de5-975a-9429c4edd44d Error: AccessDeniedException: User: arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/chaos-docker-swarm-ec2-role/i-01884ac913d430768 is not authorized to perform: ssm:UpdateInstanceInformation on resource: arn:aws:ec2:us-west-1:${data.aws_caller_identity.current.account_id}:instance/i-01884ac913d430768 because no identity-based policy allows the ssm:UpdateInstanceInformation action
  # Jan 22 19:12:33 chaos amazon-ssm-agent.amazon-ssm-agent[396]: #011status code: 400, request id: 74219e82-9bac-4de5-975a-9429c4edd44d
  # Jan 22 19:12:33 chaos amazon-ssm-agent.amazon-ssm-agent[396]: 2024-01-22 19:12:33 ERROR EC2RoleProvider Failed to connect to Systems Manager with SSM role credentials. error calling RequestManagedInstanceRoleToken: AccessDeniedException: Systems Manager's instance management role is not configured for account: ${data.aws_caller_identity.current.account_id}
  # Jan 22 19:12:33 chaos amazon-ssm-agent.amazon-ssm-agent[396]: #011status code: 400, request id: dddc5385-3328-414a-aca8-9cf2c7b2cbb1
  # Jan 22 19:12:33 chaos amazon-ssm-agent.amazon-ssm-agent[396]: 2024-01-22 19:12:33 ERROR [CredentialRefresher] Retrieve credentials produced error: no valid credentials could be retrieved for ec2 identity. Default Host Management Err: error calling RequestManagedInstanceRoleToken: AccessDeniedException: Systems Manager's instance management role is not configured for account: ${data.aws_caller_identity.current.account_id}

  statement {
    sid    = "DockerSwarmUpdateInstanceInformation"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  statement {
    sid    = "EC2CloudWatchInformation"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  # this is required so that we can modify the metadata to allow for more than 1 "hop"
  # so that we can pass it onto the containers
  # https://stackoverflow.com/questions/71884350/using-imds-v2-with-token-inside-docker-on-ec2-or-ecs/71884476#71884476
  statement {
    sid    = "DockerSwarmModifyInstanceMetadataOptions"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceMetadataOptions"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  #
  # S3
  #
  statement {
    sid    = "DockerSwarmListConfigObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.config_bucket.arn
    ]
  }

  statement {
    sid    = "DockerSwarmReadConfigObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.config_bucket.arn}/*"
    ]
  }

  #
  # SQS
  #
  statement {
    sid = "DockerSwarmSQS"
    # reference: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-api-permissions-reference.html
    actions = [
      "sqs:DeleteMessage",
      "sqs:ListQueues",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:ChangeMessageVisibility"
    ]
    # TODO this is a bit loose, allows the EC2 to use any queue in the environment
    resources = [
      "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_partition" "current" {}