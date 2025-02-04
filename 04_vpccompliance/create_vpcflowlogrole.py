import boto3
import json

# Define the IAM role name and trust policy document
role_name = "VPCFlowLogsRole"
trust_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "vpc.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

# Define the policy that grants permissions for VPC flow logs
flow_logs_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:DescribeNetworkInterfacePermissions"
            ],
            "Resource": "*"
        }
    ]
}

# Create an IAM client
iam_client = boto3.client('iam')

# Create the IAM role with the trust policy
role_response = iam_client.create_role(
    RoleName=role_name,
    AssumeRolePolicyDocument=json.dumps(trust_policy)
)

# Attach the policy to the IAM role
iam_client.put_role_policy(
    RoleName=role_name,
    PolicyName="VPCFlowLogsPolicy",
    PolicyDocument=json.dumps(flow_logs_policy)
)

# Print the ARN of the created IAM role
print(f"IAM Role ARN: {role_response['Role']['Arn']}")

