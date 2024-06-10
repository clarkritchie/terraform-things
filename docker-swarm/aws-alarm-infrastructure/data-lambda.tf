data "archive_file" "cloudwatch_slack_lambda" {
  type        = "zip"
  source_file = "cloudwatch_slack.py"
  output_path = "cloudwatch_slack.zip"
}

data "aws_iam_policy_document" "cloudwatch_slack_lambda_policy" {
  statement {
    sid    = "CreateCloudWatchLogGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*-cloudwatch-slack-lambda*"
    ]
  }

  statement {
    sid    = "CreateCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      # wildcard is to allow for any environment, e.g. dev-cloudwatch-slack-lambda, staging-cloudwatch-slack-lambda, etc.
      "arn:aws:logs:us-west-1:000000000000:log-group:/aws/lambda/*-cloudwatch-slack-lambda*"
    ]
  }
}

# allow the lambda to assume the role
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}