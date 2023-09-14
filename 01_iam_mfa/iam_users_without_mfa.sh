#!/bin/bash

# List IAM users
users=$(aws iam list-users --query 'Users[*].UserName' --output text)

# Loop through each user and check if MFA is enabled
for user in $users
do
    mfa=$(aws iam list-mfa-devices --user-name $user --query 'MFADevices[*].SerialNumber' --output text)
    if [[ -z $mfa ]]
    then
        echo "$user does not have MFA enabled"
    fi
done

