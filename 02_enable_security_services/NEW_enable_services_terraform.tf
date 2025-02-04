terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

##########################
# Provider Configuration #
##########################

# Primary provider for us-east-1
provider "aws" {
  region = "us-east-1"
}

# Secondary provider for us-west-2 using an alias.
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

###############################
# AWS Config - IAM Prerequisites
###############################

# Create an IAM role for AWS Config.
data "aws_iam_policy_document" "config_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_role" {
  name               = "aws_config_role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role_policy.json
}

# Attach the AWS managed policy for AWS Config.
resource "aws_iam_role_policy_attachment" "config_role_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

##########################
# AWS Config in us-east-1
##########################

# S3 bucket for AWS Config delivery channel in us-east-1.
resource "aws_s3_bucket" "config_bucket_east" {
  bucket = "my-aws-config-bucket-us-east-1-${random_id.bucket_id_east.hex}"
  acl    = "private"
  force_destroy = true
  tags = {
    Name = "aws-config-bucket-us-east-1"
  }
  # No explicit provider block needed here because the default is us-east-1.
}

# Generate a random suffix for bucket names to avoid collisions.
resource "random_id" "bucket_id_east" {
  byte_length = 4
}

# AWS Config configuration recorder in us-east-1.
resource "aws_config_configuration_recorder" "config_recorder_east" {
  name     = "config_recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config delivery channel in us-east-1.
resource "aws_config_delivery_channel" "delivery_channel_east" {
  name           = "config_delivery_channel"
  s3_bucket_name = aws_s3_bucket.config_bucket_east.bucket

  depends_on = [aws_config_configuration_recorder.config_recorder_east]
}

# Start the AWS Config recorder.
resource "aws_config_configuration_recorder_status" "recorder_status_east" {
  name      = aws_config_configuration_recorder.config_recorder_east.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.delivery_channel_east]
}

##########################
# AWS GuardDuty in us-east-1
##########################

resource "aws_guardduty_detector" "guardduty_east" {
  enable = true
}

##########################
# AWS Security Hub in us-east-1
##########################

resource "aws_securityhub_account" "securityhub_east" {
  # This resource registers your account with Security Hub.
  # No additional standards are enabled.
}

##########################
# AWS Config in us-west-2
##########################

# S3 bucket for AWS Config delivery channel in us-west-2.
resource "aws_s3_bucket" "config_bucket_west" {
  provider = aws.us_west_2

  bucket = "my-aws-config-bucket-us-west-2-${random_id.bucket_id_west.hex}"
  acl    = "private"
  force_destroy = true
  tags = {
    Name = "aws-config-bucket-us-west-2"
  }
}

resource "random_id" "bucket_id_west" {
  byte_length = 4
}

# AWS Config configuration recorder in us-west-2.
resource "aws_config_configuration_recorder" "config_recorder_west" {
  provider = aws.us_west_2

  name     = "config_recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config delivery channel in us-west-2.
resource "aws_config_delivery_channel" "delivery_channel_west" {
  provider       = aws.us_west_2

  name           = "config_delivery_channel"
  s3_bucket_name = aws_s3_bucket.config_bucket_west.bucket

  depends_on = [aws_config_configuration_recorder.config_recorder_west]
}

# Start the AWS Config recorder in us-west-2.
resource "aws_config_configuration_recorder_status" "recorder_status_west" {
  provider  = aws.us_west_2

  name      = aws_config_configuration_recorder.config_recorder_west.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.delivery_channel_west]
}

##########################
# AWS GuardDuty in us-west-2
##########################

resource "aws_guardduty_detector" "guardduty_west" {
  provider = aws.us_west_2

  enable = true
}

##########################
# AWS Security Hub in us-west-2
##########################

resource "aws_securityhub_account" "securityhub_west" {
  provider = aws.us_west_2
  # Registers your account with Security Hub. No standards enabled.
}


