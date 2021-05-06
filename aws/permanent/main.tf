terraform {
  backend "gcs" {
    bucket = "gleich-infra"
    prefix =  "tf/aws/permanent"
  }
}


provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_cloudwatch_metric_alarm" "one" {
  for_each = toset([for i in [0.25, 0.5, 1,3,5,10,20,30,40,50,60,70]: tostring(i)])
  actions_enabled           = true
  alarm_actions             = [
    "arn:aws:sns:us-east-1:516873755856:me",
  ]
  alarm_name                = "BillingAlert${each.value}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 1
  dimensions                = {
    "Currency" = "USD"
  }
  evaluation_periods        = 1
//  id                        = "BillingAlert$1"
  metric_name               = "EstimatedCharges"
  namespace                 = "AWS/Billing"
  period                    = 21600
  statistic                 = "Maximum"
  threshold                 = each.value
  treat_missing_data        = "missing"
}
