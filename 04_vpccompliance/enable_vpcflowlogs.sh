#!/bin/bash

# Loop through all regions
regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
for region in $regions
do
    # Loop through all VPCs in the region and enable VPC Flow Logs
    vpcs=$(aws ec2 describe-vpcs --region $region --query 'Vpcs[*].VpcId' --output text)
    for vpc in $vpcs
    do
        # Check if VPC Flow Logs are already enabled for the VPC
        flow_log_exists=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc" --region $region --query 'FlowLogs[0].FlowLogId' --output text)
        if [ -z "$flow_log_exists" ]
        then
            # If VPC Flow Logs are not enabled for the VPC, enable them
            aws ec2 create-flow-logs --resource-type VPC --resource-id $vpc --traffic-type ALL --log-group-name "vpc-flow-logs" --deliver-logs-permission-arn arn:aws:iam:::role/VPCFlowLogsRole --region $region
        fi
    done
done

