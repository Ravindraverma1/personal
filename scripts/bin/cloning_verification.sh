#!/bin/bash
#########################################################################################
#########################################################################################
#  Description  : This script is to verify the cloning activity parameters - share-rds  #
#########################################################################################

#Colors definition
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

# Condition 1 : Targeted ENVIRONMENT_NAME cannot be with "Prod" keyword.
KEYWORD='prod'
shopt -s nocasematch;
if [[ "${ENVIRONMENT_NAME}" =~ .*"$KEYWORD".* ]]; then
    echo -e "${RED} Provisioning a prod env using cloning model is prohibited. ${NOCOLOR}"
    exit 1
fi
echo -e "${GREEN} Targeted ENVIRONMENT_NAME cannot be prod : PASS ${NOCOLOR}"


#Condition 2 : If the targeted account existing customer's ENVIRONMENT_NAME contains "prod" keyword, the pipeline will fail with error message.
#Switch to SST Profile
sh ./jenkins/common/awscli-config.sh

SCAN_ENVS=$(aws dynamodb scan --region "eu-west-1" --table-name environment_config --projection-expression "env_id,customer,env,aws_region,env_account_id,z_iac_version" > environment_configs.json)
SCAN_ENVS_LIST=$(cat environment_configs.json | jq -c '.Items[] | select( .env_account_id == {"S": "'$ENVIRONMENT_AWS_ACCOUNT_ID'"}).env' | cut -d ':' -f 2 | sed 's/"//g' | sed 's/}//g')

for ENVNAME in $SCAN_ENVS_LIST
  do
    if [[ "${ENVNAME}" =~ .*"$KEYWORD".* ]]; then
        echo -e "${RED} Execution on targeted production account is prohibited. ${NOCOLOR}"
        exit 1
    fi
  done
echo -e "${GREEN} Targeted production account cannot be prod : PASS ${NOCOLOR}"


#Condition 3 : The targeted account existing customer name and pipeline targeted customer name must be equal. If they don't match, pipeline will fail with error message.
SCAN_ENVS=$(aws dynamodb scan --region "eu-west-1" --table-name environment_config --projection-expression "env_id,customer,env,aws_region,env_account_id,z_iac_version" > environment_configs.json)
SCAN_CUSTOMERS_LIST=$(cat environment_configs.json | jq -c '.Items[] | select( .env_account_id == {"S": "'$ENVIRONMENT_AWS_ACCOUNT_ID'"}).customer' | cut -d ':' -f 2 | sed 's/"//g' | sed 's/}//g')

for CUSNAME in $SCAN_CUSTOMERS_LIST
  do
    if [[ -z "${CUSNAME}" ]]; then
        echo -e "${GREEN} There is no customer env available in Targeted account ${NOCOLOR}"
    elif [[ "${CUSNAME}" == "${CUSTOMER_NAME}" ]]; then
        echo -e "${GREEN} Customer name matches ${NOCOLOR}"
    else
        echo -e " ${RED} Cloning ${CUSTOMER_NAME}-${FROM_ENVIRONMENT_NAME} env to AWS account ${ENVIRONMENT_AWS_ACCOUNT_ID} is prohibited. As this account belongs to different customer - ${CUSNAME} ${NOCOLOR}"
        exit 1
    fi
  done
echo -e "${GREEN} The targeted account existing customer name and pipeline targeted customer name must be equal : PASS ${NOCOLOR}"