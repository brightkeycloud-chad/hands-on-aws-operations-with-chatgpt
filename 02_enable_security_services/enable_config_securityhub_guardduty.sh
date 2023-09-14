#!/bin/bash

# Loop through all regions
#regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
regions="us-west-2"
for region in $regions
do
    # Enable AWS Config
    aws configservice put-configuration-recorder --configuration-recorder name=default --recording-group allSupported=true --region $region
    aws configservice start-configuration-recorder --configuration-recorder-name default --region $region
    
    # Enable Security Hub
    aws securityhub enable-security-hub --region $region
    
    # Enable GuardDuty
    aws guardduty create-detector --enable --region $region
done

