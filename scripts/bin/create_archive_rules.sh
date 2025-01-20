#!/bin/bash
#########################################################################################
#########################################################################################
#Description  : This script is to add IAM access analyzer archive rules
#########################################################################################

# Switch to ENV_AWS_PROFILE to use aws cli on customer account
. ../jenkins/common/switch-to-env-aws-profile.sh

#Setting up the region
export REGION=${CUSTOMER_REGION}
aws configure --profile ${ENV_AWS_PROFILE} set region ${REGION}

SCRIPT_HOME=../scripts

pip install --upgrade awscli --no-cache-dir --user

ARCHIVE_FILE_LIST=$(cat $SCRIPT_HOME/conf/archive_list | grep -v '^#')
FILE_PATH=$SCRIPT_HOME/src_files/archive_rule_jsons

ENVIRONMENT_AWS_ACCOUNT_ID=${2}
SST_ACCOUNT_ID=${3}
MASTER_ACCOUNT_ID=${4}
DD_ACCOUNT_ID=${5}

sed -i "s/ENVIRONMENT_AWS_ACCOUNT_ID/${ENVIRONMENT_AWS_ACCOUNT_ID}/g" ${FILE_PATH}/*
sed -i "s/SST_ACCOUNT_ID/${SST_ACCOUNT_ID}/g" ${FILE_PATH}/*
sed -i "s/MASTER_ACCOUNT_ID/${MASTER_ACCOUNT_ID}/g" ${FILE_PATH}/*
sed -i "s/DD_ACCOUNT_ID/${DD_ACCOUNT_ID}/g" ${FILE_PATH}/*

for LIST_ITEM in $ARCHIVE_FILE_LIST
  do
      RULE_NAME=$(echo $LIST_ITEM | cut -d! -f1)
      FILE_NAME=$(echo $LIST_ITEM | cut -d! -f2)
      aws accessanalyzer create-archive-rule --analyzer-name $1 --rule-name ${RULE_NAME} --filter file://${FILE_PATH}/${FILE_NAME} --region ${REGION}
  done