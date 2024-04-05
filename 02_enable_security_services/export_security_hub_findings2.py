import boto3
import json

def export_security_hub_findings(region_name, output_file):
    # Initialize a session using AWS SDK
    session = boto3.Session(region_name=region_name)
    # Get the SecurityHub client
    securityhub = session.client('securityhub')

    # Fetch the findings
    findings = []
    paginator = securityhub.get_paginator('get_findings')
    for page in paginator.paginate():
        findings.extend(page['Findings'])

    # Save the findings to a JSON file
    with open(output_file, 'w') as f:
        json.dump(findings, f, indent=4)

    print(f"Exported {len(findings)} findings to {output_file}")

# Example usage
region = 'us-east-1'  # specify the AWS region
output_file = 'security_hub_findings.json'  # output file
export_security_hub_findings(region, output_file)

