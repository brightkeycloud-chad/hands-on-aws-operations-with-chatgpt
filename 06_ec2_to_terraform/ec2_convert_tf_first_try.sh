#!/bin/bash

# Accept the EC2 instance ID as a command-line argument
instance_id=$1

# Retrieve the instance description using the AWS CLI and save it to a variable
instance_description=$(aws ec2 describe-instances --instance-ids $instance_id)

# Extract the instance details from the description using jq
instance_details=$(echo $instance_description | jq '.Reservations[].Instances[]')

# Use the instance details to create a Terraform configuration
cat <<EOF >instance.tf
resource "aws_instance" "ec2_instance" {
    ami = "${instance_details.ami.id}"
    instance_type = "${instance_details.instanceType}"
    key_name = "${instance_details.keyName}"
    subnet_id = "${instance_details.subnetId}"
    security_groups = ["${instance_details.securityGroups[].groupId}"]

    tags = {
        Name = "${instance_details.tags[].Value}"
    }
}
EOF

