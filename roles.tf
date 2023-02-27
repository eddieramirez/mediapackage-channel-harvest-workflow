resource "aws_iam_policy" "stepfunctions_permissions" {
  name        = "stepfunctions-policy"
  path        = "/"
  description = "stepfunctions permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:StartExecution"
      ],
      "Resource": "${aws_sfn_state_machine.emp_harvest_workflow.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "hourly_harvest_rule_role_stepfunctions_permissions_attachment" {
  role       = aws_iam_role.eventbridge_rule_targeting_role.name
  policy_arn = aws_iam_policy.stepfunctions_permissions.arn
}

resource "aws_iam_role" "prepare_harvest_job_function_role" {
  name = "prepare-harvest-job-function-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "prepare_harvest_job_function_role_basic_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.prepare_harvest_job_function_role.name
}
resource "aws_iam_policy" "ssm_permissions" {
  name        = "ssm-policy"
  path        = "/"
  description = "ssm permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "${aws_ssm_parameter.harvest_configuration.arn}"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "prepare_harvest_job_function_role_ssm_permissions_attachment" {
  role       = aws_iam_role.prepare_harvest_job_function_role.name
  policy_arn = aws_iam_policy.ssm_permissions.arn
}

resource "aws_iam_role" "emp_harvest_workflow_role" {
  name = "emp-harvest-workflow-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "mediapackage_permissions" {
  name        = "emp-harvest-policy"
  path        = "/"
  description = "emp permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MediaPackagePermissions",
      "Effect": "Allow",
      "Action": [
        "mediapackage:CreateHarvestJob"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PassRolePermissions",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "mediapackage.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}
resource "aws_iam_policy" "lambda_permissions" {
  name        = "lambda-policy"
  path        = "/"
  description = "lambda permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "${aws_lambda_function.prepare_harvest_job_function.arn}"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "emp_harvest_workflow_role_mediapackage_permissions_attachment" {
  role       = aws_iam_role.emp_harvest_workflow_role.name
  policy_arn = aws_iam_policy.mediapackage_permissions.arn
}
resource "aws_iam_role_policy_attachment" "emp_harvest_workflow_role_ssm_permissions_attachment" {
  role       = aws_iam_role.emp_harvest_workflow_role.name
  policy_arn = aws_iam_policy.ssm_permissions.arn
}
resource "aws_iam_role_policy_attachment" "emp_harvest_workflow_role_lambda_permissions_attachment" {
  role       = aws_iam_role.emp_harvest_workflow_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}



resource "aws_iam_role" "mediapackage_harvest_role" {
  name = "mediapackage-harvest-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": "mediapackage.amazonaws.com"
      },
      "Effect": "Allow",
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "mediapackage_harvest_permissions" {
  name        = "mediapackage-harvest-permissions"
  path        = "/"
  description = "mediapackage harvest permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${var.harvest_bucket}",
        "arn:aws:s3:::${var.harvest_bucket}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "mediapackage_harvest_role_harvest_permissions_attachment" {
  role       = aws_iam_role.mediapackage_harvest_role.name
  policy_arn = aws_iam_policy.mediapackage_harvest_permissions.arn
}
