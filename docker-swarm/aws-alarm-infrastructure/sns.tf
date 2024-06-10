resource "aws_sns_topic" "alarm_topic" {
  for_each = { for env in var.environments : env.name => env }
  name     = "${each.value.name}-alarm-topic"
  # apparantly you cannot use the AWS managed key (alias/aws/sns) with CloudWatch
  # when posting to SNS, so you have to use a CMK
  kms_master_key_id = "alias/mycompany"
  tags              = local.tags
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  for_each = {
    for env in local.env_emails : "${env.name}_${env.email_address}" => env
    if env.email_address != ""
  }

  topic_arn = aws_sns_topic.alarm_topic[each.value.name].arn
  protocol  = "email"
  endpoint  = each.value.email_address
}

resource "aws_sns_topic_subscription" "topic_slack_subscription" {
  for_each = { for env in var.environments : env.name => env }

  topic_arn = aws_sns_topic.alarm_topic[each.value.name].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_slack_lambda[each.value.name].arn
}