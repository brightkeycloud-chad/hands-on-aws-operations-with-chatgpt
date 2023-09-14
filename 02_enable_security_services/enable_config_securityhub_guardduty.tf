provider "aws" {
  region = "us-east-1" # Specify the region where the resources will be created
}

data "aws_regions" "all_regions" {} # Get all regions

resource "aws_securityhub_account" "enable" {} # Enable Security Hub

resource "aws_config_configuration_recorder" "default" { # Enable AWS Config
  name = "default"
  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "s3" { # Create S3 bucket for Config delivery channel
  name      = "config-bucket"
  s3_bucket = "config-bucket"
  prefix    = "config"
}

resource "aws_config_delivery_channel" "default" { # Enable Config delivery channel
  name          = "default"
  s3_bucket_name = aws_config_delivery_channel.s3.name
  sns_topic_arn  = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:config-topic"
}

resource "aws_guardduty_detector" "default" { # Enable GuardDuty
  depends_on = [aws_securityhub_account.enable] # GuardDuty requires Security Hub to be enabled first
}

# Loop through all regions to enable AWS Config and GuardDuty in each region
locals {
  regions = data.aws_regions.all_regions.names
}

resource "aws_config_configuration_recorder_status" "default" {
  for_each = { for region in local.regions : region => region }

  name    = "default"
  region  = each.key
  enabled = true
}

resource "aws_guardduty_detector" "all_regions" {
  for_each = { for region in local.regions : region => region }

  enable = true
  region = each.key
}

