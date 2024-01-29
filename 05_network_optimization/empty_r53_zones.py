import boto3

def list_hosted_zones_with_only_ns_and_soa():
    route53 = boto3.client('route53')

    hosted_zones = route53.list_hosted_zones()['HostedZones']

    zones_with_only_ns_soa = []

    for hosted_zone in hosted_zones:
        zone_id = hosted_zone['Id']
        zone_name = hosted_zone['Name']

        # Get all records in the hosted zone
        records = route53.list_resource_record_sets(HostedZoneId=zone_id)['ResourceRecordSets']

        # Check if there are only NS and SOA records
        if all(record['Type'] in ('NS', 'SOA') for record in records):
            zones_with_only_ns_soa.append({'ZoneName': zone_name, 'ZoneId': zone_id})

    return zones_with_only_ns_soa

def delete_hosted_zones(zones_to_delete):
    route53 = boto3.client('route53')

    for zone in zones_to_delete:
        zone_id = zone['ZoneId']
        zone_name = zone['ZoneName']

        print(f"Deleting hosted zone: {zone_name} (ID: {zone_id})")

        # Delete the hosted zone and all its records
        route53.delete_hosted_zone(Id=zone_id)

def main():
    zones_with_only_ns_soa = list_hosted_zones_with_only_ns_and_soa()

    if zones_with_only_ns_soa:
        print("AWS Route 53 hosted zones that only contain NS and SOA records:")
        for zone in zones_with_only_ns_soa:
            print(f"Zone Name: {zone['ZoneName']}, Zone ID: {zone['ZoneId']}")
        
        # Uncomment the following line to delete the identified hosted zones
        #delete_hosted_zones(zones_with_only_ns_soa)
    else:
        print("No hosted zones found that only contain NS and SOA records.")

if __name__ == '__main__':
    main()

