#!/bin/bash -ex

if [ $# -ne 5 ];then
  echo -e "\nThe S3 bucket Name and role ARN are needed\nEx: config-srv-all-regions.sh [create/destroy] [AWS Profile] [S3 Bucket Name] [Config Role ARN] [Main Region]"
  exit 1
fi

export AWS_PROFILE=$2

create_config () {
  echo -e "Create Config service in $4\n"
  # Include global resources related to IAM resources - which needs to be enabled in 1 #region only. Using the main region for this.
  includeGlobalResourceTypes=$(if [ $3 = $4 ]; then echo "true"; else echo "false"; fi)
  aws configservice put-configuration-recorder --configuration-recorder name=config-rec-$4,roleARN=$2 --recording-group allSupported=true,includeGlobalResourceTypes=${includeGlobalResourceTypes} --region $4
  aws configservice put-delivery-channel --delivery-channel name=config-delivery-$4,s3BucketName=$1,configSnapshotDeliveryProperties={deliveryFrequency="Six_Hours"} --region $4
  aws configservice start-configuration-recorder --configuration-recorder-name config-rec-$4 --region $4
}

for reg in `aws ec2 describe-regions --output text | cut -f4`
do
  RESULT=`aws configservice describe-configuration-recorders --region ${reg}|jq '.ConfigurationRecorders[]|.name'|sed -e 's/\"//g'`
  if [ "$RESULT" != "" ] ;then
    echo -e "Delete config recorder in $reg \n"
    aws configservice delete-configuration-recorder --configuration-recorder-name ${RESULT} --region ${reg}
    DEL_CHN=`aws configservice describe-delivery-channels --region ${reg} | jq '.DeliveryChannels[]|.name'|sed -e 's/\"//g'`
    if [ "$DEL_CHN" != "" ];then
      echo -e "Delete Delivery channel into $reg\n"
      aws configservice delete-delivery-channel --delivery-channel-name ${DEL_CHN} --region ${reg}
    fi
  fi
  if [ "$1" == "create" ] ;then
    create_config $3 $4 $5 $reg
  fi
done