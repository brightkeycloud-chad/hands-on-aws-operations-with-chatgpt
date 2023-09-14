#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <instance_id>"
    exit 1
fi

# Part 1: Describe the EC2 instance and save the output to a variable
instance_id="$1"
instance_details=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0]')

# Part 2: Read the instance details JSON into variables and create the Terraform template

# Read the instance details JSON into variables
instance_id=$(echo "$instance_details" | jq -r '.InstanceId')
ami=$(echo "$instance_details" | jq -r '.ImageId')
instance_type=$(echo "$instance_details" | jq -r '.InstanceType')
subnet_id=$(echo "$instance_details" | jq -r '.SubnetId')
tags=$(echo "$instance_details" | jq -r '.Tags')

# Function to parse tags into a Terraform-compatible string
parse_tags() {
    local tags_str=""
    while IFS=$'\n' read -r tag; do
        key=$(echo "$tag" | jq -r '.Key')
        value=$(echo "$tag" | jq -r '.Value')
        tags_str+=$(printf '        %s = "%s"\n' "$key" "$value")
    done <<< "$tags"
    echo "$tags_str"
}

# Create the Terraform template
terraform_template=$(cat <<EOF
resource "aws_instance" "$instance_id" {
  ami           = "$ami"
  instance_type = "$instance_type"
  subnet_id     = "$subnet_id"

  tags = {
$(parse_tags)
  }
}
EOF
)

echo "$terraform_template"

