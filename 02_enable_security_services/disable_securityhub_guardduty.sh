#!/bin/bash

# Function to disable AWS Security Hub
disable_security_hub() {
    local region="$1"
    
    # Disable AWS Security Hub
    aws securityhub disable-security-hub --region $region
}

# Function to disable AWS GuardDuty
disable_guardduty() {
    local region="$1"

    # Disable AWS GuardDuty
    aws guardduty delete-detector --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text --region $region) --region $region
}

# Loop through all regions
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
    echo "Disabling services in $region region..."
    
    disable_security_hub $region
    disable_guardduty $region
    
    echo "Services disabled in $region region."
done

