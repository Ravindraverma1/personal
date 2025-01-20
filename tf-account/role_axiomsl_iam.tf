##############################################################################
#  Default roles for ProdOps and tools
#Creates axiomsl-iam-* roles (and policies) at the account level
##############################################################################

resource "aws_iam_role" "iam-admin" {
  name = "axiomsl-iam-admin"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::282975765080:root"
     },
     "Action": "sts:AssumeRole",
     "Condition": {
       "Bool": {
         "aws:MultiFactorAuthPresent": "true"
       }
     }
   }
 ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "axIamAdminPolicy" {
  role       = aws_iam_role.iam-admin.name
  policy_arn = data.aws_iam_policy.axIamAdmin.arn
  depends_on = [aws_iam_role.iam-admin]
}

data "aws_iam_policy" "axIamAdmin" {
  arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

## NOTE: RDS ENHANCED MONITORING ROLE IS HERE BECAUSE TERRAFORM HAS PROBLEMS ATTACHING THIS ROLE
## THAT WAS CREATED ON THE SAME EXECUTION AS ATTACHING IT TO RDS FOR ENABLING ENHANCE MONITORING

#
# RDS Enhanced Monitoring Role.
#
data "aws_iam_policy_document" "rds-assume-role-policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "monitoring.rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "rds-enhc-monitoring-role" {
  name               = "axiomsl-rds-enhance-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "rds_enhance_monitoring_role_attachment" {
  role       = aws_iam_role.rds-enhc-monitoring-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  depends_on = [aws_iam_role.rds-enhc-monitoring-role]
}

resource "aws_iam_role" "iam_security" {
  name = "axiomsl-iam-security"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::282975765080:root"
     },
     "Action": "sts:AssumeRole",
     "Condition": {
       "Bool": {
         "aws:MultiFactorAuthPresent": "true"
       }
     }
   }
 ]
}
EOF

}

data "aws_iam_policy" "iam_security_policy_1" {
  arn = "arn:aws:iam::aws:policy/AWSCloudTrail_ReadOnlyAccess"
}

data "aws_iam_policy" "iam_security_policy_2" {
  arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

data "aws_iam_policy" "iam_security_policy_3" {
  arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

data "aws_iam_policy" "iam_security_policy_4" {
  arn = "arn:aws:iam::aws:policy/CloudWatchEventsReadOnlyAccess"
}

data "aws_iam_policy" "iam_security_policy_5" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

resource "aws_iam_policy" "iam_security_policy_6" {
  name        = "axiomsl-iam-config-full-access"
  path        = "/"
  description = "aws-config-full-access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "config:*",
        "tag:Get*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment1" {
  role       = aws_iam_role.iam_security.name
  policy_arn = data.aws_iam_policy.iam_security_policy_1.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment2" {
  role       = aws_iam_role.iam_security.name
  policy_arn = data.aws_iam_policy.iam_security_policy_2.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment3" {
  role       = aws_iam_role.iam_security.name
  policy_arn = data.aws_iam_policy.iam_security_policy_3.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment4" {
  role       = aws_iam_role.iam_security.name
  policy_arn = data.aws_iam_policy.iam_security_policy_4.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment5" {
  role       = aws_iam_role.iam_security.name
  policy_arn = data.aws_iam_policy.iam_security_policy_5.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role_policy_attachment" "iam_security_role_attachment6" {
  role       = aws_iam_role.iam_security.name
  policy_arn = aws_iam_policy.iam_security_policy_6.arn
  depends_on = [aws_iam_role.iam_security]
}

resource "aws_iam_role" "DatadogAWSIntegrationRole" {
  name = "axiomsl-iam-datadog-integration-role"

  assume_role_policy = <<EOF
{

  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::464622532012:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF

}

resource "aws_iam_policy" "DatadogAwsIntegrationPolicy" {
  name        = "axiomsl-iam-datadog-integration-policy"
  path        = "/"
  description = "DatadogAwsIntegrationPolicy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:Describe*",
        "budgets:ViewBudget",
        "cloudfront:GetDistributionConfig",
        "cloudfront:ListDistributions",
        "cloudtrail:DescribeTrails",
        "cloudtrail:GetTrailStatus",
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "codedeploy:List*",
        "codedeploy:BatchGet*",
        "directconnect:Describe*",
        "dynamodb:List*",
        "dynamodb:Describe*",
        "ec2:Describe*",
        "ecs:Describe*",
        "ecs:List*",
        "elasticache:Describe*",
        "elasticache:List*",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeTags",
        "elasticloadbalancing:Describe*",
        "elasticmapreduce:List*",
        "elasticmapreduce:Describe*",
        "es:ListTags",
        "es:ListDomainNames",
        "es:DescribeElasticsearchDomains",
        "firehose:*",
        "health:DescribeEvents",
        "health:DescribeEventDetails",
        "health:DescribeAffectedEntities",
        "kinesis:List*",
        "kinesis:Describe*",
        "lambda:AddPermission",
        "lambda:GetPolicy",
        "lambda:List*",
        "lambda:RemovePermission",
        "logs:Get*",
        "logs:Describe*",
        "logs:FilterLogEvents",
        "logs:TestMetricFilter",
        "logs:PutSubscriptionFilter",
        "logs:DeleteSubscriptionFilter",
        "logs:DescribeSubscriptionFilters",
        "rds:Describe*",
        "rds:List*",
        "redshift:DescribeClusters",
        "redshift:DescribeLoggingStatus",
        "route53:List*",
        "s3:GetBucketLogging",
        "s3:GetBucketLocation",
        "s3:GetBucketNotification",
        "s3:GetBucketTagging",
        "s3:ListAllMyBuckets",
        "s3:PutBucketNotification",
        "ses:Get*",
        "sns:List*",
        "sns:Publish",
        "sqs:ListQueues",
        "support:*",
        "tag:GetResources",
        "tag:GetTagKeys",
        "tag:GetTagValues"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "DatadogAwsIntegrationRole_attachment" {
  role       = aws_iam_role.DatadogAWSIntegrationRole.name
  policy_arn = aws_iam_policy.DatadogAwsIntegrationPolicy.arn
  depends_on = [aws_iam_role.DatadogAWSIntegrationRole]
}

resource "aws_iam_role" "iam-support" {
  name = "axiomsl-iam-support"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::282975765080:root"
     },
     "Action": "sts:AssumeRole",
     "Condition": {
       "BoolIfExists": {
         "aws:MultiFactorAuthPresent": "true"
       }
     }
   }
 ]
}
EOF

}

data "aws_iam_policy" "axIamSupportCloudwatch" {
  arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "axIamSupportPolicyCloudwatch" {
  role       = aws_iam_role.iam-support.name
  policy_arn = data.aws_iam_policy.axIamSupportCloudwatch.arn
  depends_on = [aws_iam_role.iam-support]
}

data "aws_iam_policy" "axIamSupportSsmPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "axIamSupportSsmPolicyAttach" {
  role       = aws_iam_role.iam-support.name
  policy_arn = data.aws_iam_policy.axIamSupportSsmPolicy.arn
  depends_on = [aws_iam_role.iam-support]
}

data "aws_iam_policy" "axIamSupportUserPolicy" {
  arn = "arn:aws:iam::aws:policy/job-function/SupportUser"
}

resource "aws_iam_role_policy_attachment" "axIamSupportUserPolicyAttach" {
  role       = aws_iam_role.iam-support.name
  policy_arn = data.aws_iam_policy.axIamSupportUserPolicy.arn
  depends_on = [aws_iam_role.iam-support]
}

resource "aws_iam_policy" "axIamSupportGenPolicy" {
  name        = "axiomsl-iam-support-gen-policy"
  path        = "/"
  description = "Generic(all inclusive) policy for prod-ops' console access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DeleteVpnConnectionRoute",
        "ec2:CreateVpnConnectionRoute",
        "ec2:EnableVgwRoutePropagation",
        "ec2:DisableVgwRoutePropagation",
        "ec2:GetVpnConnectionDeviceSampleConfiguration",
        "ec2:GetVpnConnectionDeviceTypes"
       ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
      "Action": [
        "ec2:GetConsoleOutput"
       ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
          "Action": [
              "s3:ListBucketVersions",
              "s3:GetBucketVersioning"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::axiom-test-tf-*/*",
              "arn:aws:s3:::axiom-test-tf-*",
              "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform",
              "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform/*"
          ]
    },
    {
        "Action": [
            "s3:GetObjectVersionTorrent",
            "s3:GetObject",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersion"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:s3:::axiom-test-tf-*/*",
            "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": "lambda:InvokeFunction",
        "Resource": [
            "arn:aws:lambda:*:${data.aws_caller_identity.env_account.account_id}:function:iac-tests-*",
            "arn:aws:lambda:*:${data.aws_caller_identity.env_account.account_id}:function:*-snapshot-scheduler-*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion"
        ],
        "Resource": [
            "arn:aws:s3:::*-root-control/id_rsa",
            "arn:aws:s3:::*-termination-control/disable-termination",
            "arn:aws:s3:::*-elb-access-logs/*",
            "arn:aws:s3:::*-s3-bucket-logging/*",
            "arn:aws:s3:::*-installation-data/workflow_config*",
            "arn:aws:s3:::*-installation-data/datalineage/*",
            "arn:aws:s3:::*-installation-data/SAMLServiceProviderMetadata*",
            "arn:aws:s3:::*-archival/*",
            "arn:aws:s3:::*-cw-export-logs/*",
            "arn:aws:s3:::*-emr-*/*"
        ]
    },
    {
        "Sid": "S3ExtendedSupportForSVM",
        "Effect": "Allow",
        "Action": [
            "s3:DeleteObjectTagging",
            "s3:DeleteObjectVersionTagging",
            "s3:DeleteObjectVersion",
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:GetObjectACL",
            "s3:PutObjectACL",
            "s3:PutObjectVersionTagging",
            "s3:PutObjectVersionAcl",
            "s3:PutBucketAcl"
        ],
        "Resource": "arn:aws:s3:::*-installation-data/workflow_config*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "guardduty:GetThreatIntelSet",
            "guardduty:GetIPSet"
        ],
        "Resource": [
            "arn:aws:guardduty:*:*:detector/*/ipset/*",
            "arn:aws:guardduty:*:*:detector/*/threatintelset/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "guardduty:ListIPSets",
            "guardduty:GetFindings",
            "guardduty:ListThreatIntelSets",
            "guardduty:GetThreatIntelSet",
            "guardduty:GetMasterAccount",
            "guardduty:GetIPSet",
            "guardduty:ListFindings",
            "guardduty:GetMembers",
            "guardduty:GetFindingsStatistics",
            "guardduty:GetDetector",
            "guardduty:ListMembers",
            "guardduty:GetFreeTrialStatistics"
        ],
        "Resource": "arn:aws:guardduty:*:*:detector/*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "guardduty:ListFilters",
            "guardduty:ListDetectors",
            "guardduty:GetInvitationsCount",
            "guardduty:ListInvitations"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:GetTransitGatewayRouteTableAssociations",
            "ec2:GetTransitGatewayRouteTablePropagations",
            "ec2:GetTransitGatewayAttachmentPropagations",
            "ec2:SearchTransitGatewayRoutes"
        ],
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "config:Get*",
        "config:Describe*",
        "config:Deliver*",
        "config:List*"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "pi:*",
        "Resource": "arn:aws:pi:*:*:metrics/rds/*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObjectVersionTorrent",
            "s3:GetObject",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersion"
        ],
        "Resource": "arn:aws:s3:::*-application-logs/*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "backup:DescribeBackupJob",
            "backup:DescribeCopyJob",
            "backup:DescribeProtectedResource",
            "backup:DescribeRecoveryPoint",
            "backup:DescribeRestoreJob",
            "backup:ExportBackupPlanTemplate",
            "backup:GetBackupPlanFromJSON",
            "backup:GetBackupPlanFromTemplate",
            "backup:GetRecoveryPointRestoreMetadata",
            "backup:GetSupportedResourceTypes",
            "backup:ListBackupJobs",
            "backup:ListBackupPlanTemplates",
            "backup:ListBackupPlans",
            "backup:ListBackupVaults",
            "backup:ListCopyJobs",
            "backup:ListProtectedResources",
            "backup:ListRecoveryPointsByResource",
            "backup:ListRestoreJobs",
            "backup:ListTags"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "backup:GetBackupPlan",
            "backup:GetBackupSelection",
            "backup:ListBackupPlanVersions",
            "backup:ListBackupSelections"
        ],
        "Resource": "arn:aws:backup:*:*:backup-plan:*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "backup:DescribeBackupVault",
            "backup:GetBackupVaultNotifications",
            "backup:GetBackupVaultAccessPolicy",
            "backup:ListRecoveryPointsByBackupVault"
        ],
        "Resource": "arn:aws:backup:*:*:backup-vault:*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ds:*",
            "workspaces:*"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "elasticmapreduce:Describe*",
            "elasticmapreduce:Get*",
            "elasticmapreduce:List*",
            "emr-containers:ListVirtualClusters",
            "elasticmapreduce:ViewEventsFromAllClustersInConsole",
            "glue:GetDatabase",
            "glue:GetDatabases",
            "glue:GetTable",
            "glue:GetTables",
            "glue:GetPartition",
            "glue:GetPartitions",
            "glue:BatchGetPartition"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "elasticmapreduce:Describe*",
            "emr-containers:Describe*",
            "elasticmapreduce:Get*",
            "elasticmapreduce:List*",
            "emr-containers:List*"
        ],
        "Resource": [
            "arn:aws:emr-containers:*:*:/virtualclusters/*/jobruns/*",
            "arn:aws:emr-containers:*:*:/virtualclusters/*/endpoints/*",
            "arn:aws:elasticmapreduce:*:*:notebook-execution/*",
            "arn:aws:elasticmapreduce:*:*:editor/*",
            "arn:aws:elasticmapreduce:*:*:studio/*",
            "arn:aws:elasticmapreduce:*:*:cluster/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "emr-containers:DescribeVirtualCluster",
            "emr-containers:List*"
        ],
        "Resource": "arn:aws:emr-containers:*:*:/virtualclusters/*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "axIamSupportGenPolicyAttach" {
  role       = aws_iam_role.iam-support.name
  policy_arn = aws_iam_policy.axIamSupportGenPolicy.arn
  depends_on = [aws_iam_role.iam-support]
}

resource "aws_iam_role_policy_attachment" "axIamSuperSupportAttach" {
  role       = aws_iam_role.iam-super-support.name
  policy_arn = aws_iam_policy.axIamSuperSupportPolicy.arn
  depends_on = [aws_iam_role.iam-super-support]
}

resource "aws_iam_role" "iam-super-support" {
  name = "axiomsl-iam-supersupport"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::282975765080:root"
     },
     "Action": "sts:AssumeRole",
     "Condition": {
       "BoolIfExists": {
         "aws:MultiFactorAuthPresent": "true"
       }
     }
   }
 ]
}
EOF

}

resource "aws_iam_policy" "axIamSuperSupportPolicy" {
  name        = "axiomsl-iam-super-support-policy"
  path        = "/"
  description = "Super support access for prodops manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "VPCRouteUpdate",
        "Action": [
            "ec2:DeleteVpnConnectionRoute",
            "ec2:CreateVpnConnectionRoute",
            "ec2:CreateRoute",
            "ec2:DeleteRoute",
            "ec2:DeleteRouteTable",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeClassicLinkInstances",
            "ec2:DescribeCustomerGateways",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeEgressOnlyInternetGateways",
            "ec2:DescribeFlowLogs",
            "ec2:DescribeInstances",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeMovingAddresses",
            "ec2:DescribeNatGateways",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeNetworkInterfaceAttribute",
            "ec2:DescribeNetworkInterfacePermissions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribePrefixLists",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroupReferences",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeStaleSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcClassicLink",
            "ec2:DescribeVpcClassicLinkDnsSupport",
            "ec2:DescribeVpcEndpointConnectionNotifications",
            "ec2:DescribeVpcEndpointConnections",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcEndpointServiceConfigurations",
            "ec2:DescribeVpcEndpointServicePermissions",
            "ec2:DescribeVpcEndpointServices",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpnConnections",
            "ec2:DescribeVpnGateways",
            "ec2:DisableVgwRoutePropagation",
            "ec2:DisassociateAddress",
            "ec2:DisassociateRouteTable",
            "ec2:DisassociateSubnetCidrBlock",
            "ec2:DisassociateVpcCidrBlock",
            "ec2:EnableVgwRoutePropagation",
            "ec2:EnableVpcClassicLink",
            "ec2:EnableVpcClassicLinkDnsSupport",
            "ec2:ReplaceRoute",
            "ec2:ReplaceRouteTableAssociation",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:GetTransitGatewayRouteTableAssociations",
            "ec2:GetTransitGatewayRouteTablePropagations",
            "ec2:GetTransitGatewayAttachmentPropagations",
            "ec2:SearchTransitGatewayRoutes"
        ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
        "Sid": "IAMReadOnly",
        "Action": [
            "iam:GenerateCredentialReport",
            "iam:GenerateServiceLastAccessedDetails",
            "iam:Get*",
            "iam:List*",
            "iam:SimulateCustomPolicy",
            "iam:SimulatePrincipalPolicy",
            "access-analyzer:*"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
          "Sid": "S3SupportList",
          "Action": [
              "s3:ListBucket",
              "s3:ListAllMyBuckets",
              "s3:ListBucketVersions",
              "s3:GetBucketVersioning"
          ],
          "Effect": "Allow",
          "Resource": "*"
    },
    {
        "Sid": "S3Support",
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:DeleteObjectVersion",
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:GetObjectVersionTagging"
        ],
        "Resource": [
            "arn:aws:s3:::*-root-control/*",
            "arn:aws:s3:::*-termination-control/*",
            "arn:aws:s3:::*-elb-access-logs/*",
            "arn:aws:s3:::*-s3-bucket-logging/*",
            "arn:aws:s3:::*-installation-data/*",
            "arn:aws:s3:::*-archival/*",
            "arn:aws:s3:::*-cw-export-logs/*",
            "arn:aws:s3:::axiom-test-tf-*/*",
            "arn:aws:s3:::axiom-test-tf-*",
            "arn:aws:s3:::*-emr-*/*",
            "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform",
            "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform/*"
        ]
    },
    {
        "Sid": "S3ExtendedSupportForTFState",
        "Effect": "Allow",
        "Action": [
            "s3:DeleteObjectTagging",
            "s3:DeleteObjectVersionTagging",
            "s3:GetObjectACL",
            "s3:PutObjectACL",
            "s3:PutObjectVersionTagging",
            "s3:PutObjectVersionAcl",
            "s3:PutBucketAcl"
        ],
        "Resource": [
            "arn:aws:s3:::axiom-test-tf-*/*",
            "arn:aws:s3:::axiom-test-tf-*",
            "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform",
            "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform/*"
        ]
    },
    {
        "Sid": "WorkspaceMgmt",
        "Effect": "Allow",
        "Action": [
            "ds:*",
            "workspaces:*"
        ],
        "Resource": "*"
    },
    {
        "Sid": "RDSSnapshotDeletionandRestore",
        "Effect": "Allow",
        "Action": [
            "rds:Describe*",
            "rds:RestoreDBInstanceFromDBSnapshot",
            "rds:RestoreDBClusterFromSnapshot",
            "rds:RestoreDBInstanceToPointInTime",
            "rds:DeleteDBClusterSnapshot",
            "rds:DeleteDBSnapshot"
        ],
        "Resource": "*"
    },
    {
        "Sid": "ReadDBLogFilesSupport",
        "Effect": "Allow",
        "Action": [
            "rds:ListTagsForResource",
            "rds:Download*"
        ],
        "Resource": "arn:aws:rds:*:${data.aws_caller_identity.env_account.account_id}:db:*"
    },
    {
        "Sid": "SSMPutPermission",
        "Effect": "Allow",
        "Action": [
            "ssm:PutParameter"
        ],
        "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.env_account.account_id}:parameter/*"
    },
    {
        "Sid": "ComputeOptimizerAndSparkSupport",
        "Effect": "Allow",
        "Action": [
            "compute-optimizer:Update*",
            "compute-optimizer:Describe*",
            "compute-optimizer:Export*",
            "compute-optimizer:Get*",
            "elasticmapreduce:*",
            "emr-containers:*"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "elasticmapreduce:*",
            "emr-containers:*"
        ],
        "Resource": [
            "arn:aws:emr-containers:*:*:/virtualclusters/*/jobruns/*",
            "arn:aws:emr-containers:*:*:/virtualclusters/*/endpoints/*",
            "arn:aws:emr-containers:*:*:/virtualclusters/*",
            "arn:aws:elasticmapreduce:*:*:notebook-execution/*",
            "arn:aws:elasticmapreduce:*:*:editor/*",
            "arn:aws:elasticmapreduce:*:*:studio/*",
            "arn:aws:elasticmapreduce:*:*:cluster/*"
        ]
    }
  ]
}
EOF
}

data "aws_iam_policy" "axIamSuperSupportUserPolicy" {
  arn = "arn:aws:iam::aws:policy/job-function/SupportUser"
}

resource "aws_iam_role_policy_attachment" "axIamSuperSupportUserPolicyAttach" {
  role       = aws_iam_role.iam-super-support.name
  policy_arn = data.aws_iam_policy.axIamSuperSupportUserPolicy.arn
  depends_on = [aws_iam_role.iam-super-support]
}

data "aws_iam_policy" "axIamSuperSupportSsmPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "axIamSuperSupportSsmPolicyAttach" {
  role       = aws_iam_role.iam-super-support.name
  policy_arn = data.aws_iam_policy.axIamSuperSupportSsmPolicy.arn
  depends_on = [aws_iam_role.iam-super-support]
}
