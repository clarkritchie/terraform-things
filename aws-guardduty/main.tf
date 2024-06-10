resource "aws_sns_topic" "guardduty_alerts_topic" {
  name              = "guardduty-topic"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "guardduty_topic_email_subscription" {
  for_each  = toset(var.emails)
  topic_arn = aws_sns_topic.guardduty_alerts_topic.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_guardduty_detector" "main" {
  count  = var.create_detector ? 1 : 0
  enable = true
}

resource "aws_cloudwatch_event_rule" "main" {
  name          = "guardduty-finding-events"
  description   = "AWS GuardDuty event findings"
  event_pattern = file("${path.module}/event-pattern.json")
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "send-to-sns-slack"
  arn       = aws_sns_topic.guardduty_alerts_topic.arn
}