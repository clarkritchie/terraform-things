# The value of the ServerlessDatabaseCapacity metric divided by the maximum ACU value of the DB cluster
# If this metric approaches a value of 100.0, the DB instance has scaled up as high as it can. Consider increasing the maximum ACU setting for the cluster. That way, both writer and reader DB instances can scale to a higher capacity.
# Suppose that a read-only workload causes a reader DB instance to approach an ACUUtilization of 100.0, while the writer DB instance isn't close to its maximum capacity. In that case, consider adding additional reader DB instances to the cluster. That way, you can spread the read-only part of the workload spread across more DB instances, reducing the load on each reader DB instance.
# Suppose that you are running a production application, where performance and scalability are the primary considerations. In that case, you can set the maximum ACU value for the cluster to a high number. Your goal is for the ACUUtilization metric to always be below 100.0. With a high maximum ACU value, you can be confident that there's enough room in case there are unexpected spikes in database activity. You are only charged for the database capacity that's actually consumed.
#
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.setting-capacity.html

# This is a major WAG
resource "aws_cloudwatch_metric_alarm" "acu_utilization_alarm" {
  alarm_name          = "${var.environment}-MySQL-ACU-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ACUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  alarm_description = "Alarm when ACU Utilization is high for MySQL Serverless in ${var.environment}"
  alarm_actions     = [var.alarm_arn]
  ok_actions        = [var.alarm_arn]
  tags              = local.tags
}