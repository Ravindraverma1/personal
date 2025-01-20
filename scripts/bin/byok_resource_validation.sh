#!/bin/bash
#########################################################################################
#########################################################################################
#  Description  : This script is to verify the byok alias - enable-byok#
#########################################################################################
#Colors definition
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

# set customer profile and variables
TIMEZONE=$(jenkins/common/get-config customer_timezone)
ENABLE_BYOK=$(jenkins/common/get-config enable_byok)
CMK_OF_WORM_S3_FF=$(jenkins/common/get-config enable_worm_compliance)
CMK_OF_PGP_FF=$(jenkins/common/get-config enable_pgp)

export TZ=${TIMEZONE}
DATE=`date +"%Y%m%d-%H%M%S"`

SCRIPT_HOME=./scripts
FILE_PATH=$SCRIPT_HOME/conf/byok_tf_map.conf
sed -i "s/CUSTOMER/${CUSTOMER_NAME}/g" ${FILE_PATH} > /dev/null
sed -i "s/ENV/${ENVIRONMENT_NAME}/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_RDS_ENCRYPTION_KEY/true/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_PGP_FF/${CMK_OF_PGP_FF}/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_DEFAULT_S3_FF/true/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_ARCHIVE_FF/true/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_REPORTING_FF/true/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_WORM_S3_FF/${CMK_OF_WORM_S3_FF}/g" ${FILE_PATH} > /dev/null
sed -i "s/UPDATE_CMK_OF_OUTBOUND_TRANSFER/true/g" ${FILE_PATH} > /dev/null

BYOK_FILE_LIST=$(cat ${FILE_PATH} | grep -v '^#')

for LIST_ITEM in $BYOK_FILE_LIST
  do
      INPUT_KEY_NAME=$(echo $LIST_ITEM | cut -d! -f1)
      OLD_ALIAS=$(echo $LIST_ITEM | cut -d! -f2)
      NEW_ALIAS=$(echo $LIST_ITEM | cut -d! -f3)
      TF_KEY_NAME=$(echo $LIST_ITEM | cut -d! -f4)
      TF_ALIAS_NAME=$(echo $LIST_ITEM | cut -d! -f5)

      if [ "${ENABLE_BYOK}" != "true" ]
      then
          echo -e "${GREEN} enabling BYOK on an existing environment first time.${NOCOLOR}"
          if [ "${INPUT_KEY_NAME}" == "true" ]
          then
              TARGET_KEYID=$(aws kms list-aliases --profile ${ENV_AWS_PROFILE} | jq -r '.Aliases[] | select( .AliasName == "'${OLD_ALIAS}'" ).TargetKeyId' || true )
              if [ -n "${TARGET_KEYID}" ]
              then
                aws kms create-alias --alias-name ${OLD_ALIAS}-old-$DATE --target-key-id ${TARGET_KEYID} --profile ${ENV_AWS_PROFILE} || true
                aws kms delete-alias --alias-name ${OLD_ALIAS} --profile ${ENV_AWS_PROFILE} || true
                terraform12 state rm ${TF_KEY_NAME} || true
                terraform12 state rm ${TF_ALIAS_NAME} || true
              else
                terraform12 state rm ${TF_KEY_NAME} || true
                terraform12 state rm ${TF_ALIAS_NAME} || true
                echo "already removed from the state and backed up"
              fi
          else
            echo -e  "${GREEN} ${OLD_ALIAS} is not been used in the targeted environment. You may execute the respective pipeline to enable this option if customer want to use it.${NOCOLOR}"
          fi
      else
        echo "BYOK is alreay enabled"
        if [ "${INPUT_KEY_NAME}" == "true" ]
        then
            TARGET_KEY_ID=$(aws kms list-aliases --profile ${ENV_AWS_PROFILE} | jq -r '.Aliases[] | select( .AliasName == "'${NEW_ALIAS}'").TargetKeyId' || true)
            if [ -z "${TARGET_KEY_ID}" ]
            then
                echo -e "${RED} ${NEW_ALIAS} is not found. Plz ask customer to push the key using correct ALIAS.${NOCOLOR}"
                exit 1
            else
                echo -e "${GREEN} ${NEW_ALIAS} is found.${NOCOLOR}"
            fi
        else
          echo -e  "${GREEN} ${OLD_ALIAS} is not been used in the targeted environment. You may execute the respective pipeline to enable this option if customer want to use it.${NOCOLOR}"
        fi
      fi
  done