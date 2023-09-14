#!/bin/bash

# Set your desired role name
ROLE_NAME="VPCFlowLogsRole"

# Create the IAM role
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# Attach the required policy to the IAM role
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

# Verify that the role has been created and the policy attached
aws iam get-role --role-name $ROLE_NAME

