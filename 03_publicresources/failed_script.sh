#!/bin/bash

# Get a list of all regions using the AWS CLI
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Loop through each region and identify all public resources
for region in $regions
do
  echo "Checking region $region..."
  
  # Get a list of all public EC2 instances in the region using the AWS CLI
  public_instances=$(aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=ip-address,Values=*" --query 'Reservations[*].Instances[*].{ID:InstanceId,PublicDNS:PublicDnsName,PublicIP:PublicIpAddress,SecurityGroups:SecurityGroups[*].GroupName}' --output table)

  # Print the list of public EC2 instances to the console
  echo "$public_instances"
  
  # Get a list of all public load balancers in the region using the AWS CLI
  public_load_balancers=$(aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[?Scheme==`internet-facing`].{DNSName:DNSName}' --output table)

  # Print the list of public load balancers to the console
  echo "$public_load_balancers"
  
  # Get a list of all public S3 buckets in the region using the AWS CLI
  public_s3_buckets=$(aws s3api list-buckets --region $region --query 'Buckets[?((PublicAccessBlockConfiguration.PublicAccessBlockConfiguration.EnablePublicBlock==`false` || PublicAccessBlockConfiguration==null) && LocationConstraint==`'$region'`)].{Name:Name,CreationDate:CreationDate}' --output table)

  # Print the list of public S3 buckets to the console
  echo "$public_s3_buckets"

  # Get a list of all security groups in the region using the AWS CLI
  security_groups=$(aws ec2 describe-security-groups --region $region --query 'SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId,IpPermissions:IpPermissions}' --output table)

  # Loop through each security group and check if it has an inbound rule allowing traffic from any IP address
  for row in $(echo "$security_groups" | tail -n +4)
  do
    group_id=$(echo $row | awk '{print $2}')
    permissions=$(echo $row | awk '{print $3}')

    for permission in $(echo $permissions | tr "," "\n")
    do
      protocol=$(echo $permission | awk -F":" '{print $1}')
      from_port=$(echo $permission | awk -F":" '{print $2}')
      to_port=$(echo $permission | awk -F":" '{print $3}')
      cidr=$(echo $permission | awk -F":" '{print $5}')
      
      if [ "$cidr" == "0.0.0.0/0" ]
      then
        echo "Security group $group_id allows traffic from any IP address (protocol: $protocol, port range: $from_port-$to_port)"
      fi
    done
  done
done

