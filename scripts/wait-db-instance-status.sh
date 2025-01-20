#!/bin/bash
CUSTOMER_REGION=$(jenkins/common/get-config aws_region)

DBINSTANCESTATUS=$(aws --profile $1 rds describe-db-instances --db-instance-identifier \
  "$2" --region ${CUSTOMER_REGION} | jq -r '.DBInstances[].DBInstanceStatus')

if [ ! -z "$DBINSTANCESTATUS" ]; then
  ELAPSED_TIME=0
  while [ ${DBINSTANCESTATUS} != "$3" ] && [ $ELAPSED_TIME -le "$4" ]
  do
    sleep 10s
    ELAPSED_TIME=$(( ELAPSED_TIME + 10 ))
    DBINSTANCESTATUS=$(aws --profile $1 rds describe-db-instances --db-instance-identifier \
    "$2" --region ${CUSTOMER_REGION} | jq -r '.DBInstances[].DBInstanceStatus')
  done
fi
