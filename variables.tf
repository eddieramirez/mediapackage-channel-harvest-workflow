variable "account_id" {
  description = "account id"
  type    = number
}
variable "region_name" {
  description = "region name"
  type    = string
}

variable "channel_configuration" {
  description = "channel_configuration"
  type = list(object({
    channelName = string
    medialiveChannelId = string
    mediapackageChannelId = string
    mediapackageOriginEndpointId = string
  }))
}
variable "harvest_bucket" {
  description = "s3 bucket for harvest jobs"
  type    = string
}
variable "harvest_prefix" {
  description = "s3 bucket prefix for harvest jobs"
  type    = string
}
