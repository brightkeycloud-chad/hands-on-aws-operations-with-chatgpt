#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <region> <parameter_group_name>"
    exit 1
fi

region="$1"
parameter_group_name="$2"

# Describe the parameters in the specified parameter group
parameter_info=$(aws rds describe-db-parameters --region "$region" --db-parameter-group-name "$parameter_group_name" --output json)

# Filter parameters that have a Source value of "Custom"
custom_parameters=$(echo "$parameter_info" | jq -r '.Parameters[] | select(.Source == "user") | .ParameterName, .ParameterValue')

# Output the list of custom parameters with their values
if [ -n "$custom_parameters" ]; then
    echo "Custom parameters in parameter group '$parameter_group_name' in region '$region':"
    echo "$custom_parameters" | while read -r parameter_name; do
        read -r parameter_value
        echo "Parameter: $parameter_name"
        echo "  - Value: $parameter_value"
    done
else
    echo "No custom parameters found in parameter group '$parameter_group_name' in region '$region'"
fi

