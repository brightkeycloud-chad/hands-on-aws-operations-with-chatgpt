#!/bin/bash

#region="your_aws_region"
region="us-east-1"
input_file="deleted_snapshot_ids.txt"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# Loop through each snapshot ID in the input file and delete the snapshot
while read -r snapshot_id; do
    echo "Deleting snapshot: $snapshot_id"
    aws ec2 delete-snapshot --region "$region" --snapshot-id "$snapshot_id"
done < "$input_file"

