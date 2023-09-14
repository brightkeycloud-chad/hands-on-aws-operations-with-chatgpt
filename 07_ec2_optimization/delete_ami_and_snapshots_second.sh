#!/bin/bash

region="your_aws_region"
older_than_days=180
current_date=$(date +%s)

# Get a list of all AMIs in the specified region
ami_list=$(aws ec2 describe-images --region "$region" --query 'Images[*].[ImageId, CreationDate]' --output text)

# Loop through each AMI to check if it's older than 180 days
while read -r ami_id creation_date; do
    # Convert the AMI creation date to UNIX timestamp
    ami_timestamp=$(date -d "$creation_date" +%s)

    # Calculate the age of the AMI in days
    age_days=$(( (current_date - ami_timestamp) / (60*60*24) ))

    # If the AMI is older than 180 days, deregister it and delete associated snapshots
    if [ "$age_days" -gt "$older_than_days" ]; then
        # Get a list of snapshots associated with the AMI
        snapshot_ids=$(aws ec2 describe-images --region "$region" --image-ids "$ami_id" --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)

        echo "Deregistering AMI: $ami_id (Created: $creation_date)"
        aws ec2 deregister-image --image-id "$ami_id" --region "$region"

        # Loop through each snapshot and delete it
        for snapshot_id in $snapshot_ids; do
            echo "Deleting Snapshot: $snapshot_id"
            aws ec2 delete-snapshot --snapshot-id "$snapshot_id" --region "$region"
        done
    fi
done <<< "$ami_list"

