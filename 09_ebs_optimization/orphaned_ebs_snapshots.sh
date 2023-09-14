#!/bin/bash

#region="your_aws_region"
region="us-east-1"
output_file="deleted_snapshot_ids.txt"

# Get a list of all EBS volume IDs in the specified region
volume_ids=$(aws ec2 describe-volumes --region "$region" --query 'Volumes[*].[VolumeId]' --output text)

# Get a list of all EBS snapshots owned by your AWS account and with the "OKTODELETE" tag
snapshot_info=$(aws ec2 describe-snapshots --region "$region" --owner-ids self --query 'Snapshots[?Tags[?Key==`OKTODELETE`]].SnapshotId' --output json)

# Output the snapshot IDs for which the volume has been previously deleted
> "$output_file"
while read -r snapshot_id; do
    volume_id=$(aws ec2 describe-snapshots --region "$region" --snapshot-ids "$snapshot_id" --query 'Snapshots[0].VolumeId' --output text)
    if ! echo "$volume_ids" | grep -q "$volume_id"; then
        echo "$snapshot_id" >> "$output_file"
    fi
done < <(echo "$snapshot_info" | jq -r '.[]')

