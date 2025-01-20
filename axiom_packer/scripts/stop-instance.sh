#!/bin/bash
AZ=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone/)
AWS_REGION=${AZ::-1}
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
ASG_NAME=$(aws ec2 describe-tags --region ${AWS_REGION} --filters "Name=resource-id,Values=${INSTANCE_ID}" --query 'Tags[?Key==`aws:autoscaling:groupName`]'.Value --output text)
echo aws autoscaling set-desired-capacity --region ${AWS_REGION} --auto-scaling-group-name ${ASG_NAME} --desired-capacity 0
aws autoscaling set-desired-capacity --region ${AWS_REGION} --auto-scaling-group-name ${ASG_NAME} --desired-capacity 0
rt=$?
echo "Return code: ${rt}"
