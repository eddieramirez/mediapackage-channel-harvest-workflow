resource "aws_ssm_parameter" "harvest_configuration" {
  name  = "harvest-configuration"
  type  = "String"
  value = jsonencode({
    bucketInformation = {
      bucket = var.harvest_bucket
      prefix = var.harvest_prefix
    }
    channelConfiguration = var.channel_configuration
  })
}
