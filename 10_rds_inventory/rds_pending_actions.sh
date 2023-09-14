#!/bin/bash

# Get a list of all AWS regions
regions=$(aws ec2 describe-regions --query 'Regions[*].[RegionName]' --output text)

# Loop through each region and identify RDS instances with pending actions
for region in $regions; do
    echo "Checking region: $region"

    # Get a list of RDS instances in the current region with pending actions
    pending_instances=$(aws rds describe-db-instances --region "$region" --query 'DBInstances[?PendingModifiedValues].{InstanceIdentifier: DBInstanceIdentifier, PendingModifiedValues: PendingModifiedValues}' --output json)

    # Output the list of instances with pending actions
    if [ -n "$pending_instances" ]; then
        echo "$pending_instances" | jq -r '.[] | "Instance: \(.InstanceIdentifier)\nPending Actions: \(.PendingModifiedValues)\n"'
    else
        echo "No instances with pending actions in $region"
    fi

    echo
done

