# The value of the ServerlessDatabaseCapacity metric divided by the maximum ACU value of the DB cluster
# If this metric approaches a value of 100.0, the DB instance has scaled up as high as it can. Consider increasing the maximum ACU setting for the cluster. That way, both writer and reader DB instances can scale to a higher capacity.
# Suppose that a read-only workload causes a reader DB instance to approach an ACUUtilization of 100.0, while the writer DB instance isn't close to its maximum capacity. In that case, consider adding additional reader DB instances to the cluster. That way, you can spread the read-only part of the workload spread across more DB instances, reducing the load on each reader DB instance.
# Suppose that you are running a production application, where performance and scalability are the primary considerations. In that case, you can set the maximum ACU value for the cluster to a high number. Your goal is for the ACUUtilization metric to always be below 100.0. With a high maximum ACU value, you can be confident that there's enough room in case there are unexpected spikes in database activity. You are only charged for the database capacity that's actually consumed.
#
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.setting-capacity.html

# This is a major WAG
resource "aws_cloudwatch_metric_alarm" "acu_utilization_alarm" {
  alarm_name          = "${var.environment}-postgres-acu-utilization"
  alarm_description   = "Alarm when ACU Utilization is high for Postgres Serverless in ${var.environment}"
  actions_enabled     = var.alarm_actions_enabled
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ACUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

# Note: It's unclear if any of these alarms are useful or even needed

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  for_each          = module.postgres_serverless.cluster_instances
  alarm_name        = "${var.environment}-postgres-cpu-${each.value.identifier}"
  alarm_description = "This alarm helps to monitor consistent high CPU utilization. CPU utilization measures non-idle time. Consider using [Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html) or [Performance Insights](https://aws.amazon.com/rds/performance-insights/) to review which [wait time](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring-Available-OS-Metrics.html) is consuming the most of the CPU time (`guest`, `irq`, `wait`, `nice`, etc) for MariaDB, MySQL, Oracle, and PostgreSQL. Then evaluate which queries consume the highest amount of CPU. If you cannot tune your workload, consider moving to a larger DB instance class."
  actions_enabled   = var.alarm_actions_enabled
  metric_name       = "CPUUtilization"
  namespace         = "AWS/RDS"
  statistic         = "Average"
  period            = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_load_alarm" {
  for_each          = module.postgres_serverless.cluster_instances
  alarm_name        = "${var.environment}-postgres-db-load-${each.value.identifier}"
  alarm_description = "This alarm helps to monitor high DB load. If the number of processes exceed the number of vCPUs, the processes start queuing. When the queuing increases, the performance is impacted. If the DB load is often above the maximum vCPU, and the primary wait state is CPU, the CPU is overloaded. In this case, you can monitor `CPUUtilization`, `DBLoadCPU` and  queued tasks in Performance Insights/Enhanced Monitoring. You might want to throttle connections to the instance, tune any SQL queries with a high CPU load, or consider a larger instance class. High and consistent instances of any wait state indicate that there might be bottlenecks or resource contention issues to resolve."
  actions_enabled   = var.alarm_actions_enabled
  metric_name       = "DBLoad"
  namespace         = "AWS/RDS"
  statistic         = "Average"
  period            = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 15
  datapoints_to_alarm = 15
  threshold           = 5 # this is a WAG
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_throughput_credit_alarm" {
  for_each          = module.postgres_serverless.cluster_instances
  alarm_name        = "${var.environment}-postgres-es-byte-balance-${each.value.identifier}"
  alarm_description = "This alarm helps to monitor a low percentage of throughput credits remaining. For troubleshooting, check [latency problems in RDS](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck)."
  actions_enabled   = var.alarm_actions_enabled
  metric_name       = "EBSByteBalance%"
  namespace         = "AWS/RDS"
  statistic         = "Average"
  period            = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 10
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_iops_credits_alarm" {
  for_each          = module.postgres_serverless.cluster_instances
  alarm_name        = "${var.environment}-postgres-esiobalance-${each.value.identifier}"
  alarm_description = "This alarm helps to monitor low percentage of IOPS credits remaining. For troubleshooting, see [latency problems in RDS](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck)."
  actions_enabled   = var.alarm_actions_enabled
  metric_name       = "EBSIOBalance%"
  namespace         = "AWS/RDS"
  statistic         = "Average"
  period            = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 10
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_read_latency_alarm" {
  for_each           = module.postgres_serverless.cluster_instances
  alarm_name         = "${var.environment}-postgres-read-latency-${each.value.identifier}"
  alarm_description  = "This alarm helps to monitor high read latency. If storage latency is high, it's because the workload is exceeding resource limits. You can review I/O utilization relative to instance and allocated storage configuration. Refer to [troubleshoot the latency of Amazon EBS volumes caused by an IOPS bottleneck](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck). For Aurora, you can switch to an instance class that has [I/O-Optimized storage configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html). See [Planning I/O in Aurora](https://aws.amazon.com/blogs/database/planning-i-o-in-amazon-aurora/) for guidance."
  actions_enabled    = var.alarm_actions_enabled
  metric_name        = "ReadLatency"
  namespace          = "AWS/RDS"
  extended_statistic = "p90"
  period             = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 150 # this is a major WAG
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_write_latency_alarm" {
  for_each           = module.postgres_serverless.cluster_instances
  alarm_name         = "${var.environment}-postgres-write-latency-${each.value.identifier}"
  alarm_description  = "This alarm helps to monitor high write latency. If storage latency is high, it's because the workload is exceeding resource limits. You can review I/O utilization relative to instance and allocated storage configuration. Refer to [troubleshoot the latency of Amazon EBS volumes caused by an IOPS bottleneck](https://repost.aws/knowledge-center/rds-latency-ebs-iops-bottleneck). For Aurora, you can switch to an instance class that has [I/O-Optimized storage configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.storage-type.html). See [Planning I/O in Aurora](https://aws.amazon.com/blogs/database/planning-i-o-in-amazon-aurora/) for guidance."
  metric_name        = "WriteLatency"
  namespace          = "AWS/RDS"
  extended_statistic = "p90"
  period             = 60
  dimensions = {
    DBInstanceIdentifier = each.value.identifier
  }
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 150 # this is a major WAG
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [var.alarm_arn]
  ok_actions          = [var.alarm_arn]
  tags                = local.tags
}