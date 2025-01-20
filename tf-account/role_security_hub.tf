resource "aws_iam_role_policy" "security_hub_policy" {
  name = "security_hub_policy"
  role = aws_iam_role.security-hub-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": [
                        "securityhub.amazonaws.com",
                        "config.amazonaws.com"
                    ]
                }
            },
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "securityhub:*",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "config:DescribeConfigurationRecorders",
                "config:DescribeDeliveryChannels",
                "config:DescribeConfigurationRecorderStatus",
                "config:DeleteConfigurationRecorder",
                "config:DeleteDeliveryChannel",
                "config:PutConfigurationRecorder",
                "config:PutDeliveryChannel",
                "config:StartConfigurationRecorder"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:CreateBucket",
                "s3:PutBucketPolicy",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::config-bucket-*",
            "Effect": "Allow"
        }
    ]
}
EOF

}

resource "aws_iam_role" "security-hub-role" {
  name = "axiomsl-securityhub"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::${var.sst_account_id}:role/jenkins-role"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF

}

