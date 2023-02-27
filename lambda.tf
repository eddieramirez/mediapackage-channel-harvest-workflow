data "archive_file" "prepare_harvest_job_function_source" {
  type        = "zip"
  output_path = "/tmp/prepareHarvestJob.zip"
  source_dir  = "functions/prepareHarvestJob"
}
resource "aws_lambda_function" "prepare_harvest_job_function" {
  function_name = "prepare-harvest-job-function"
  runtime = "nodejs18.x"

  role = aws_iam_role.prepare_harvest_job_function_role.arn

  filename          = data.archive_file.prepare_harvest_job_function_source.output_path
  source_code_hash  = data.archive_file.prepare_harvest_job_function_source.output_base64sha256
  handler           = "index.handler"

  environment {
    variables = {
      harvestConfigurationParameterName = aws_ssm_parameter.harvest_configuration.name
    }
  }
}
