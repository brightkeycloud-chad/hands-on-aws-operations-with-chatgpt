#!/bin/bash

# Get a list of all regions using AWS CLI
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

# Loop through each region
for region in $regions; do
    echo "Checking resources in region: $region"

    # Get a list of all VPCs in the region
    vpcs=$(aws ec2 describe-vpcs --query "Vpcs[*].VpcId" --output text --region "$region")

    # Loop through each VPC
    for vpc in $vpcs; do
        # Get a list of all resources in the VPC that have public IP addresses
        resources_with_public_ip=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc" "Name=association.public-ip,Values=*" --query "NetworkInterfaces[*].{ResourceId:Attachment.InstanceId, Resource:Attachment.InstanceOwnerId, ResourceType:Attachment.InstanceType, PublicIP:Association.PublicIp}" --output json --region "$region")

        # Check if there are any resources with public IP addresses in the VPC
        if [ -n "$resources_with_public_ip" ]; then
            echo "Resources with public IP addresses in VPC '$vpc' (Region: $region):"
            echo "$resources_with_public_ip" | jq .
        else
            echo "No resources with public IP addresses found in VPC '$vpc' (Region: $region)."
        fi
    done
done

