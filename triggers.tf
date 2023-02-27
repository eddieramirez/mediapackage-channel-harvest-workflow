resource "aws_cloudwatch_event_rule" "channel_stop_harvest" {
  name        = "channel-stop-harvest"
  description = "trigger channel stop harvest"

  event_pattern = <<EOF
{
  "source": [
    "aws.medialive"
  ],
  "detail-type": [
    "MediaLive Channel State Change"
  ],
  "detail": {
    "message": [
      "Stop detected on pipeline"
    ]
  }
}
EOF
}
resource "aws_cloudwatch_event_target" "channel_stop_harvest_target" {
  rule      = aws_cloudwatch_event_rule.channel_stop_harvest.name
  target_id = "channel_stop_harvest_target"
  role_arn  = aws_iam_role.eventbridge_rule_targeting_role.arn
  arn       = aws_sfn_state_machine.emp_harvest_workflow.arn
}

resource "aws_iam_role" "eventbridge_rule_targeting_role" {
  name = "eventbridge-rule-targeting-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "hourly_harvest" {
  name        = "hourly-harvest"
  description = "trigger hourly harvest"

  schedule_expression = "cron(0 * ? * * *)"
}
resource "aws_cloudwatch_event_target" "hourly_harvest_target" {
  rule      = aws_cloudwatch_event_rule.hourly_harvest.name
  target_id = "hourly_harvest_target"
  role_arn  = aws_iam_role.eventbridge_rule_targeting_role.arn
  arn       = aws_sfn_state_machine.emp_harvest_workflow.arn
}
