#!/bin/bash

# Loop through all regions
regions=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
for region in $regions
do
    # Loop through all VPCs in the region and create Gateway Endpoint
    vpcs=$(aws ec2 describe-vpcs --region $region --query 'Vpcs[*].VpcId' --output text)
    for vpc in $vpcs
    do
        # Check if Gateway Endpoint is already created for the VPC
        endpoint_exists=$(aws ec2 describe-vpc-endpoints --filter "Name=vpc-id,Values=$vpc" --region $region --query 'VpcEndpoints[?ServiceName==`com.amazonaws.'$region'.s3`].VpcEndpointId' --output text)
        if [ -z "$endpoint_exists" ]
        then
            # If Gateway Endpoint is not created for the VPC, create it
            endpoint_id=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --service-name com.amazonaws.$region.s3 --route-table-ids $(aws ec2 describe-route-tables --region $region --filters Name=vpc-id,Values=$vpc --query 'RouteTables[*].RouteTableId' --output text) --region $region --query 'VpcEndpoint.VpcEndpointId' --output text)
            echo "Created Gateway Endpoint with ID $endpoint_id in VPC $vpc in region $region"
        else
            echo "Gateway Endpoint already exists for VPC $vpc in region $region with ID $endpoint_exists"
        fi

        # Get the prefix list ID for the S3 service in the region
        # prefix_list_id=$(aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=AmazonS3 --region $region --query 'PrefixLists[*].PrefixListId' --output text)

        # Create a route in the VPC's route table to use the Gateway Endpoint
        # route_exists=$(aws ec2 describe-route-tables --region $region --filters Name=vpc-id,Values=$vpc Name=route.destination-prefix-list-id,Values=$prefix_list_id --query 'RouteTables[*].Routes[*].GatewayId' --output text)
        # if [ -z "$route_exists" ]
        # then
        #     # If the route does not exist, create it
        #     aws ec2 create-route --route-table-id $(aws ec2 describe-route-tables --region $region --filters Name=vpc-id,Values=$vpc --query 'RouteTables[*].RouteTableId' --output text) --destination-prefix-list-id $prefix_list_id --gateway-id $endpoint_id --region $region
        #     echo "Created route to Gateway Endpoint in VPC $vpc in region $region"
        # else
        #     echo "Route already exists to Gateway Endpoint in VPC $vpc in region $region"
        # fi
    done
done

