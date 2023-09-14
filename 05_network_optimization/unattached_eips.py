import boto3

def list_unassociated_eips(region):
    ec2 = boto3.client('ec2', region_name=region)
    unassociated_eips = []

    # List all EIP addresses
    eips = ec2.describe_addresses()

    for eip in eips['Addresses']:
        if 'AssociationId' not in eip:
            unassociated_eips.append(eip)

    return unassociated_eips

def release_eips(region, eip_list):
    ec2 = boto3.client('ec2', region_name=region)

    for eip in eip_list:
        if eip['Domain'] == 'vpc':
            print(f"Releasing unassociated VPC EIP: {eip['PublicIp']}")
            ec2.release_address(AllocationId=eip['AllocationId'])
        else:
            print(f"Releasing unassociated EC2-Classic EIP: {eip['PublicIp']}")
            ec2.release_address(PublicIp=eip['PublicIp'])

def main():
    # Get a list of all AWS regions
    ec2_client = boto3.client('ec2')
    regions = [region['RegionName'] for region in ec2_client.describe_regions()['Regions']]

    for region in regions:
        print(f"Checking unassociated EIPs in region: {region}")
        unassociated_eips = list_unassociated_eips(region)

        if unassociated_eips:
            print(f"Found unassociated EIPs in region {region}:")
            for eip in unassociated_eips:
                print(f"- {eip['PublicIp']} ({eip['Domain']})")
            release_eips(region, unassociated_eips)
        else:
            print(f"No unassociated EIPs found in region: {region}")

if __name__ == '__main__':
    main()

