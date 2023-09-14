#!/bin/bash

# Set the AWS region
AWS_REGION="us-east-1"

# Get the current date in a macOS-compatible format
CURRENT_DATE=$(date -u "+%Y-%m-%dT%H:%M:%SZ")

# Iterate through each IAM user
aws iam list-users --region $AWS_REGION --output json | jq -r '.Users[] | .UserName' | while read -r USER
do
    # List the access keys for the user
    ACCESS_KEYS=$(aws iam list-access-keys --region $AWS_REGION --user-name $USER --output json | jq -r '.AccessKeyMetadata[] | select(.Status == "Active") | select(.CreateDate < "'$CURRENT_DATE'") | .AccessKeyId')

    # Check if any access keys are older than 365 days
    if [ -n "$ACCESS_KEYS" ]; then
        echo "User $USER has the following access keys older than 365 days:"
        echo "$ACCESS_KEYS"
    fi
done

