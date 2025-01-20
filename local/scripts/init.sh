#!/bin/bash -ex
#

pushd ${AGENT_WORKDIR}

echo "git 'checkout'"
rm -rf * || true
cp -r /repo/* .

set -a
. ./local/properties/global.properties
. ./local/properties/${ENV_ID}.properties
set +a

export BUILD_URL="jenkins-local_"`date +%Y%m%d%H%M%S`

export ENV_AWS_PROFILE=${ENV_ID}

echo "Preparation"
#./jenkins/common/awscli-config.sh # Assumed done manually in mounted .aws volume
python3 ./jenkins/common/dynamo-cli.py get-dynamo
python3 ./jenkins/common/dynamo-cli.py resync-domain
python3 ./jenkins/common/dynamo-cli.py resync-infra
#./jenkins/common/awscli-config-terraform.sh # Assumed done manually in mounted .aws volume

echo "Run initialization scripts"
./jenkins/common/initialize-terraform.sh