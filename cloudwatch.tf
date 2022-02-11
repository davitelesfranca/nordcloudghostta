resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name                = "cpu-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120" #seconds
  statistic                 = "Average"
  threshold                 = "80" #porcentage
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = aws_launch_configuration.nordcloud_lc.id


  }

  alarm_actions = ["${aws_autoscaling_policy.autopolicy.arn}"]

}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_down" {
  alarm_name                = "cpu-utilization-down"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120" #seconds
  statistic                 = "Average"
  threshold                 = "80" #porcentage
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = aws_launch_configuration.nordcloud_lc.id
  }

  alarm_actions = ["${aws_autoscaling_policy.autopolicy_down.arn}"]

}
