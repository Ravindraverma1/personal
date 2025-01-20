{
    "Version": "2012-10-17",
    "Id": "key-policy-1",
    "Statement": [
        {
            "Sid": "Enable IAM User and service linked role Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [                    
                    "arn:aws:iam::${accountid}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
                    "arn:aws:iam::${accountid}:root"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}