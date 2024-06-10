resource "aws_iam_role" "cloudwatch_slack_lambda_role" {
  name               = "cloudwatch-slack-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  tags               = local.tags
}

resource "aws_iam_policy" "cloudwatch_slack_lambda_policy" {
  name        = "cloudwatch-slack-lambda-policy"
  description = "Allows the cloudwatch-slack-lambda-policy lambda to forawrd CloudWatch Alarms to Slack"
  policy      = data.aws_iam_policy_document.cloudwatch_slack_lambda_policy.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_slack_lambda_policy" {
  role       = aws_iam_role.cloudwatch_slack_lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_slack_lambda_policy.arn
}

resource "aws_lambda_function" "cloudwatch_slack_lambda" {
  for_each = { for env in var.environments : env.name => env }

  filename         = "cloudwatch_slack.zip"
  function_name    = "${each.key}-cloudwatch-slack-lambda"
  description      = "This lambda forwards CloudWatch Alarms (via SNS) to Slack for the ${each.key} environment"
  role             = aws_iam_role.cloudwatch_slack_lambda_role.arn
  handler          = "cloudwatch_slack.lambda_handler" # filename.function_name
  source_code_hash = data.archive_file.cloudwatch_slack_lambda.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      SLACK_WEBHOOK_URL = each.value.slack_webhook_url
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "cloudwatch_slack_lambda_logs" {
  for_each = { for env in var.environments : env.name => env }
  name     = "/aws/lambda/${each.key}-cloudwatch-slack-lambda"

  tags              = local.tags
  retention_in_days = 7
}

resource "aws_lambda_permission" "with_sns" {
  for_each      = { for env in var.environments : env.name => env }
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_slack_lambda[each.key].arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarm_topic[each.key].arn
}