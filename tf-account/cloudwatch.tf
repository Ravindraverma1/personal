###CW resources for cloudtrail tracking
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "cis-global-cloudtrail-log-group"
  kms_key_id        = var.cloudtrail_kms_arn_audit_account
  retention_in_days = 7
}

# ----------------------
# watch for unauthorized API calls CIS 3.1
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "unauthz_api" {
  name           = "Unauthorized-api-call"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "UnauthorizedApiCalls"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# watch for use of the console without MFA CIS 3.2
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "console_without_mfa" {
  name           = "console-without-mfa"
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "ConsoleWithoutMFACount"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# watch for use of the root account  CIS 3.3
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "root-access"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "RootAccessCount"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for changes to IAM resources CIS 3.4
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "iam_change" {
  name           = "iam-changes"
  pattern        = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "IamChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for CloudTrail Configuration Changes CIS 3.5
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "cloudtrail-config-changes" {
  name           = "cloudtrail-config-changes"
  pattern        = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "CloudTrailConfigChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for AWS Management Console authentication failures CIS 3.6
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "auth_failure" {
  name           = "auth_failure"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "IamChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for disabling or scheduled deletion of customer created CMKs  CIS 3.7
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "cmk_deletion" {
  name           = "cmk_deletion"
  pattern        = "{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion))}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "CmkDeletion"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for S3 bucket policy changes CIS 3.8
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy" {
  name           = "s3_bucket_policy"
  pattern        = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "S3BucketPolicy"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for AWS Config configuration changes CIS 3.9
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "aws_config_policy" {
  name           = "aws_config_policy"
  pattern        = "{($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder))}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "AwsConfigChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# Ensure a log metric filter and alarm exist for security group changes CIS 3.10
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "sg_changes" {
  name           = "sg_changes"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup)}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "SGChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for Network Access Control Lists (NACL) changes CIS 3.11
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name           = "nacl_changes"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "NACLChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for network gateways changes CIS 3.12
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "netgw_changes" {
  name           = "netgw_changes"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "NETGWChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for route table changes CIS 3.13
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "rt_changes" {
  name           = "rt_changes"
  pattern        = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "RTChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

# ----------------------
# look for VPC changes CIS 3.14
# ----------------------
resource "aws_cloudwatch_log_metric_filter" "vpc_changes" {
  name           = "vpc_changes"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "VPCChanges"
    namespace = "cis-global-metrics"
    value     = "1"
  }
}

