locals {
  env_emails = flatten([
    for e in var.environments : [
      for email_address in e.emails : {
        name          = e.name
        email_address = email_address
      }
    ]
  ])

  alarm_topic_arns = [for topic in aws_sns_topic.alarm_topic : topic.arn]

  tags = {
    Terraform = "True"
  }
}