#!/bin/bash -x
CUSTOMER_REGION="$3"

INVITATION_ARN=$(aws --profile $1 ram get-resource-share-invitations --resource-share-arns \
  "$2" --region ${CUSTOMER_REGION} | jq -r '.resourceShareInvitations[] | select( .status == "PENDING").resourceShareInvitationArn')

if [ ! -z "$INVITATION_ARN" ]; then
    aws --profile $1 ram accept-resource-share-invitation --resource-share-invitation-arn ${INVITATION_ARN} --region ${CUSTOMER_REGION}
    # wait for 60 secs for completion
    sleep 60
fi
