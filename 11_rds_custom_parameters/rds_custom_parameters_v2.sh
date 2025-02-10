#!/bin/bash
# Usage: ./get-custom-parameters.sh <region> <rds-parameter-group-name>
#
# This script retrieves custom (non-engine-default and non-system) parameters for an RDS
# parameter group and outputs a CSV with the ParameterName, CurrentValue, and the
# corresponding engine default value (if available).

# Check if exactly two arguments are provided.
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <region> <rds-parameter-group-name>"
  exit 1
fi

REGION="$1"
PARAMETER_GROUP="$2"

echo "Fetching custom parameters for RDS Parameter Group '$PARAMETER_GROUP' in region '$REGION'..."

# 1. Determine the parameter group family.
GROUP_FAMILY=$(aws rds describe-db-parameter-groups \
  --region "$REGION" \
  --db-parameter-group-name "$PARAMETER_GROUP" \
  --query "DBParameterGroups[0].DBParameterGroupFamily" \
  --output text)

if [ -z "$GROUP_FAMILY" ]; then
  echo "Error: Could not determine the parameter group family for '$PARAMETER_GROUP'."
  exit 1
fi

# 2. Get the engine default parameters for the family.
ENGINE_DEFAULTS=$(aws rds describe-engine-default-parameters \
  --region "$REGION" \
  --db-parameter-group-family "$GROUP_FAMILY" )

# 3. Retrieve custom parameters from the parameter group.
#    Exclude parameters whose Source is "engine-default" or "system".
CUSTOM_PARAMETERS=$(aws rds describe-db-parameters \
  --region "$REGION" \
  --db-parameter-group-name "$PARAMETER_GROUP" \
  --query "Parameters[?Source!='engine-default' && Source!='system']" \
  --output json)

# 4. Output CSV header.
echo "ParameterName,CurrentValue,DefaultValue"

# 5. For each custom parameter, look up the engine default value (if available)
#    and output a CSV row.
#
# We use 'jq' to process JSON. (Ensure that jq is installed.)
echo "$CUSTOM_PARAMETERS" | jq -c '.[]' | while read -r param; do
  # Extract parameter name and current (custom) value.
  param_name=$(echo "$param" | jq -r '.ParameterName')
  current_value=$(echo "$param" | jq -r '.ParameterValue // "null"')

  # Look up the default value in the ENGINE_DEFAULTS output.
  default_value=$(echo "$ENGINE_DEFAULTS" | \
    jq -r --arg name "$param_name" '.EngineDefaults.Parameters[] | select(.ParameterName == $name) | .ParameterValue // "null"' | head -n1)
  
  # If no default value was found, set it to "null".
  if [ -z "$default_value" ]; then
    default_value="null"
  fi

  # Output CSV row (values are wrapped in double quotes to handle commas and spaces).
  echo "\"$param_name\",\"$current_value\",\"$default_value\""
done
