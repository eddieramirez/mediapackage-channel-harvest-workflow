provider "aws" {
  region = var.region_name
  allowed_account_ids = [var.account_id]
}
