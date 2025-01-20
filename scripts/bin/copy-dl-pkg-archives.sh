#!/bin/bash -x

# Switch to ENV_AWS_PROFILE to use aws cli on customer account
. jenkins/common/switch-to-env-aws-profile.sh

CV_VERSION=`echo $(./jenkins/common/get-config cv_version) | tr -s _ .| cut -f1-3 -d \.`
UPGRADE_S3_URL="s3://axiom-data-transfer/datalineage/upgrade/${CV_VERSION}/"
FRESH_S3_URL="s3://axiom-data-transfer/datalineage/fresh_installation/${CV_VERSION}/"
export_DLS_S3_URL="s3://axiom-data-transfer/datalineage/common/export_DLS_V10.zip"
DEST_S3_URL="s3://axiom-solution-deployment"
UPGRADE_VERSIONS=`aws s3 ls "${UPGRADE_S3_URL}"`
DEPLOY_DL_VERSION=${2}
INSTALLATION_TYPE=${3}
LICENSE_TYPE=${4}
mkdir -p /tmp/{wo_tracer,with_tracer}

if [ "${INSTALLATION_TYPE}" == "DEPLOY-DL" ] && [ "${LICENSE_TYPE}" == "default" ]
then
   aws s3 cp "${FRESH_S3_URL}${DEPLOY_DL_VERSION}/wo_tracer/" /tmp/wo_tracer/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
   aws s3 cp "${export_DLS_S3_URL}" /tmp/wo_tracer/ --acl bucket-owner-full-control
   aws s3 cp "/tmp/wo_tracer/" "${DEST_S3_URL}-$1"/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
elif [ "${INSTALLATION_TYPE}" == "DEPLOY-DL" ] && [ "${LICENSE_TYPE}" == "tracer" ]
then
   aws s3 cp "${FRESH_S3_URL}${DEPLOY_DL_VERSION}/with_tracer/" /tmp/with_tracer/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
   aws s3 cp "${export_DLS_S3_URL}" /tmp/with_tracer/ --acl bucket-owner-full-control
   aws s3 cp "/tmp/with_tracer/" "${DEST_S3_URL}-$1"/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"

elif [ "${INSTALLATION_TYPE}" == "UPGRADE-DL" ] && [ "${LICENSE_TYPE}" == "default" ] &&  [[ "${UPGRADE_VERSIONS}" == *"$DEPLOY_DL_VERSION"* ]]     # check if version is supported and copy files to env bucket
then
     aws s3 cp "${UPGRADE_S3_URL}${DEPLOY_DL_VERSION}/wo_tracer/" /tmp/wo_tracer/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
     aws s3 cp "/tmp/wo_tracer/" "${DEST_S3_URL}-$1"/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"

elif [ "${INSTALLATION_TYPE}" == "UPGRADE-DL" ] && [ "${LICENSE_TYPE}" == "tracer" ] &&  [[ "${UPGRADE_VERSIONS}" == *"$DEPLOY_DL_VERSION"* ]]     # check if version is supported and copy files to env bucket
then
     aws s3 cp "${UPGRADE_S3_URL}${DEPLOY_DL_VERSION}/with_tracer/" /tmp/with_tracer/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
     aws s3 cp "/tmp/with_tracer/" "${DEST_S3_URL}-$1"/ --acl bucket-owner-full-control --recursive --exclude "*" --include "*"
else
 echo "${DEPLOY_DL_VERSION} is not supported at ${CV_VERSION}"
 exit 1
fi