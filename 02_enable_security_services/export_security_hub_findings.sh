#!/bin/bash

# Set the output file name
OUTPUT_FILE="security_hub_findings.csv"

# Get all Security Hub findings
aws securityhub get-findings --query 'Findings[*]' --output json | jq -r '
  .[] | 
  { 
    SeverityLabel: .Severity.Label, 
    ProductName: .ProductFields.ProductName, 
    Description: .Description, 
    Resources: (.Resources[] | .Type) 
  } | 
  [.SeverityLabel, .ProductName, .Description, (.Resources | join(","))] | 
  @csv' > "$OUTPUT_FILE"

echo "Security Hub findings exported to $OUTPUT_FILE in CSV format."

