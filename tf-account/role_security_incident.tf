resource "aws_iam_role_policy" "sg_incident_policy" {
  name = "sg-incident-policy"
  role = aws_iam_role.sg_incident_lambda_iam.id

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": "config:PutEvaluations",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:security-group/*",
              "Condition": {
                "StringEquals": {
                  "ec2:Vpc": "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:vpc/*"
                }
              }
        },
        {
            "Effect": "Allow",
            "Action": [
               "s3:ListAllMyBuckets",
               "s3:ListBucket",
               "s3:GetObject"

            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
EOF

}

resource "aws_iam_role" "sg_incident_lambda_iam" {
  name = "sg-incident-lambda-iam"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "instance_incident_policy" {
  name = "unauthorized-instance-incident-policy"
  role = aws_iam_role.instance_incident_lambda_iam.id

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": "config:PutEvaluations",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                  "ec2:Vpc": "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:vpc/*"
                }
            }
        }
    ]
}
EOF

}

resource "aws_iam_role" "instance_incident_lambda_iam" {
  name = "unauthorized-instance-incident-lambda-iam"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "guardduty_instance_incident_policy" {
  name = "guardduty-instance-incident-policy"
  role = aws_iam_role.guardduty_instance_incident_role.id

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "config:PutEvaluations",
                "ec2:*",
                "s3:*",
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": [
                "arn:aws:config:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*",
                "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*",
                "arn:aws:s3:::*",
                "arn:aws:ses:${var.ses_aws_region}:${data.aws_caller_identity.env_account.account_id}:*",
                "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"
            ],
            "Condition":{
                "ForAllValues:StringLike": {
                    "ses:Recipients": ["${join("\",\"", var.account_alerts_domains)}"]
                }
            }
        }
    ]
}
EOF

}

resource "aws_iam_role" "guardduty_instance_incident_role" {
  name = "guardduty-instance-incident-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "config_rules_non_compliant_policy" {
  name = "config_rules_non_compliant_policy"
  role = aws_iam_role.config_rules_non_compliant_role.id

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": [
                "arn:aws:ses:${var.ses_aws_region}:${data.aws_caller_identity.env_account.account_id}:*",
                "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"
            ],
            "Condition":{
                "ForAllValues:StringLike": {
                    "ses:Recipients": ["${join("\",\"", var.account_alerts_domains)}"]
                }
            }
        }
    ]
}
EOF

}

resource "aws_iam_role" "config_rules_non_compliant_role" {
  name = "config_rules_non_compliant_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

