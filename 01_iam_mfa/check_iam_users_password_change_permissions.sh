#!/bin/bash

# Define the name of the policy you want to check for
POLICY_NAME="IAMUserChangePassword"

# List all IAM users
IAM_USERS=$(aws iam list-users --output json | jq -r '.Users[].UserName')

# Iterate through each IAM user
for USER in $IAM_USERS
do
    # Get the policies attached to the user
    USER_POLICIES=$(aws iam list-attached-user-policies --user-name $USER --output json | jq -r '.AttachedPolicies[].PolicyName')

    # Get the groups that the user is a member of
    USER_GROUPS=$(aws iam list-groups-for-user --user-name $USER --output json | jq -r '.Groups[].GroupName')

    # Iterate through the groups and get their policies
    for GROUP in $USER_GROUPS
    do
        GROUP_POLICIES=$(aws iam list-attached-group-policies --group-name $GROUP --output json | jq -r '.AttachedPolicies[].PolicyName')
        USER_POLICIES+=" $GROUP_POLICIES"
    done

    # Check if the required policy is attached to the user or any of its groups
    if [[ $USER_POLICIES != *$POLICY_NAME* ]]
    then
        echo "User $USER does not have the $POLICY_NAME policy attached."
    fi
done

