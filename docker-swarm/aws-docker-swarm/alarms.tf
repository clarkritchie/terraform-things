# list available metrics:
# aws cloudwatch list-metrics --namespace "AWS/EC2" --region us-west-1

resource "aws_cloudwatch_metric_alarm" "cpu_credit_balance_alarm" {
  count               = length(local.all_instance_ids)
  alarm_name          = "${var.environment}-low-cpu-credit-balance-${local.all_instance_ids[count.index]}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Alarm when CPU credit balance falls below 100 on ${local.all_instance_ids[count.index]}"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
  dimensions = {
    InstanceId = local.all_instance_ids[count.index]
  }
}

# terraform apply -target aws_cloudwatch_metric_alarm.high_cpu_alarm -var-file chaos.tfvars
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  count               = length(local.all_instance_ids)
  alarm_name          = "${var.environment}-high-cpu-utilization-${local.all_instance_ids[count.index]}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when CPU utilization exceeds 80% on ${local.all_instance_ids[count.index]}"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
  dimensions = {
    InstanceId = local.all_instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_usage_anomaly_alarm" {
  count               = length(local.all_instance_ids)
  alarm_name          = "${var.environment}-cpu-utilization-anomaly-${local.all_instance_ids[count.index]}"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "Alarm when EC2 exhibits CPU usage anomalies"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1)"
    label       = "CPUUtilization (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      period      = 120
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        InstanceId = local.all_instance_ids[count.index]
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "nlb_healthyhosts" {
  alarm_name          = "${var.environment}-nlb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when there are unhealthy hosts in ELB target group"
  actions_enabled     = "true"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
  dimensions = {
    TargetGroup  = aws_lb_target_group.docker_swarm_tg.arn
    LoadBalancer = aws_lb.docker_swarm_lb.arn
  }
}

# this appears to not be available in us-west-1
# resource "aws_cloudwatch_metric_alarm" "disk_space_alarm" {
#   count               = length(local.all_instance_ids)
#   alarm_name          = "${var.environment}-low-disk-space-${local.all_instance_ids[count.index]}"
#   alarm_description   = "Alarms when used disk space is greater than 80%"
#   metric_name         = "DiskSpaceUtilization"
#   namespace           = "AWS/EC2"
#   statistic           = "Average"
#   period              = 300
#   evaluation_periods  = 2
#   threshold           = 80
#   comparison_operator = "GreaterThanThreshold"
#   alarm_actions       = [var.alarm_arn]
#   ok_actions          = [var.alarm_arn]

#   dimensions = {
#     InstanceId = local.all_instance_ids[count.index]
#   }

#   tags                = local.tags
# }

resource "aws_cloudwatch_metric_alarm" "status_check_failed_alarm" {
  count               = length(local.all_instance_ids)
  alarm_name          = "${var.environment}-status-check-failed-alarm-${local.all_instance_ids[count.index]}"
  alarm_description   = "Alarm when EC2 status checks fail"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
  dimensions = {
    InstanceId = local.all_instance_ids[count.index]
  }
}
