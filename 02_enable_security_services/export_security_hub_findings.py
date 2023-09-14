import boto3
import csv

# Set the AWS region
AWS_REGION = 'us-east-1'

# Initialize the Security Hub client
client = boto3.client('securityhub', region_name=AWS_REGION)

# Get all Security Hub findings
findings = []

paginator = client.get_paginator('get_findings')
for page in paginator.paginate():
    findings.extend(page['Findings'])

# Define the CSV output file
output_file = 'security_hub_findings.csv'

# Extract relevant fields and write to CSV
with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
    fieldnames = ['SeverityLabel', 'ProductName', 'Description', 'ResourceTypes', 'ResourceIds']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()

    for finding in findings:
        severity_label = finding['Severity']['Label']
        product_name = finding['ProductArn'].split(':product/')[1] if 'ProductArn' in finding else 'N/A'
        description = finding.get('Description', 'N/A')
        
        resource_types = ', '.join([resource['Type'] for resource in finding.get('Resources', [])])
        resource_ids = ', '.join([resource['Id'] for resource in finding.get('Resources', [])])

        writer.writerow({
            'SeverityLabel': severity_label,
            'ProductName': product_name,
            'Description': description,
            'ResourceTypes': resource_types,
            'ResourceIds': resource_ids
        })

print(f"Security Hub findings exported to {output_file} in CSV format.")

