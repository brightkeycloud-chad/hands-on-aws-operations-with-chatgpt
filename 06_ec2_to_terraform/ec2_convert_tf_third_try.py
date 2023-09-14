import boto3
import argparse

# Function to describe an EC2 instance and its tags
def describe_ec2_instance(region, instance_id):
    try:
        # Initialize Boto3 EC2 client
        ec2 = boto3.client('ec2', region_name=region)

        # Describe the EC2 instance
        response = ec2.describe_instances(InstanceIds=[instance_id])

        if not response['Reservations']:
            print("No instance found with the provided ID.")
            return None

        instance = response['Reservations'][0]['Instances'][0]
        return instance

    except Exception as e:
        print(f"Error: {e}")
        return None

# Function to generate Terraform template
def generate_terraform_template(instance):
    template = f'''
resource "aws_instance" "example" {{
  ami           = "{instance['ImageId']}"
  instance_type = "{instance['InstanceType']}"
  key_name      = "{instance['KeyName']}"

  subnet_id     = "{instance['SubnetId']}"
  vpc_security_group_ids = [{', '.join([f'"{sg["GroupId"]}"' for sg in instance['SecurityGroups']])}]

  tags = {{
'''

    for tag in instance.get('Tags', []):
        template += f'    "{tag["Key"]}" = "{tag["Value"]}"\n'

    template += '  }\n}\n'

    return template

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Terraform template for an EC2 instance.')
    parser.add_argument('region', help='AWS region where the EC2 instance is located')
    parser.add_argument('instance_id', help='EC2 instance ID')
    
    args = parser.parse_args()

    instance_info = describe_ec2_instance(args.region, args.instance_id)

    if instance_info:
        terraform_template = generate_terraform_template(instance_info)

        # Print the Terraform template
        print("\nTerraform Template:")
        print(terraform_template)

