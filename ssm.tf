resource "aws_kms_key" "ssm" {
  description         = "SSM Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true

  tags = {
    Name        = "ssm-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "ssm-alias" {
  name          = "alias/ssm-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.ssm.key_id
}

resource "null_resource" "generate-rds-password" {
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/database_password' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "database_password" {
  depends_on = [null_resource.generate-rds-password]
  name       = "/${var.customer}/${var.env}/database_password"
}

###
# Database Users
###

# DB users created in TF are:
#  * axiom_meta_user
#  * axiom_meta_ro_user
#  * axiom_ro_user

# Password for "axiom_meta_user"
resource "null_resource" "db_axiom_meta_user" {
  count = var.db_axiom_meta_user == "" || var.db_axiom_meta_user == " " ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/db_axiom_meta_user' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "db_axiom_meta_user" {
  count      = var.db_axiom_meta_user == "" || var.db_axiom_meta_user == " " ? 1 : 0
  depends_on = [null_resource.db_axiom_meta_user]
  name       = "/${var.customer}/${var.env}/db_axiom_meta_user"
}

# Password for "axiom_meta_ro_user"
resource "null_resource" "db_axiom_meta_ro_user" {
  count = var.db_axiom_meta_ro_user == "" || var.db_axiom_meta_ro_user == " " ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/db_axiom_meta_ro_user' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "db_axiom_meta_ro_user" {
  count      = var.db_axiom_meta_ro_user == "" || var.db_axiom_meta_ro_user == " " ? 1 : 0
  depends_on = [null_resource.db_axiom_meta_ro_user]
  name       = "/${var.customer}/${var.env}/db_axiom_meta_ro_user"
}

# Password for "axiom_ro_user"
resource "null_resource" "db_axiom_ro_user" {
  count = var.db_axiom_ro_user == "" || var.db_axiom_ro_user == " " ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/db_axiom_ro_user' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "db_axiom_ro_user" {
  count      = var.db_axiom_ro_user == "" || var.db_axiom_ro_user == " " ? 1 : 0
  depends_on = [null_resource.db_axiom_ro_user]
  name       = "/${var.customer}/${var.env}/db_axiom_ro_user"
}

# Password for "local_admin"
resource "null_resource" "db_local_admin_user" {
  count = var.db_local_admin_user == "" || var.db_local_admin_user == " " ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/db_local_admin_user' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "db_local_admin_user" {
  count      = var.db_local_admin_user == "" || var.db_local_admin_user == " " ? 1 : 0
  depends_on = [null_resource.db_local_admin_user]
  name       = "/${var.customer}/${var.env}/db_local_admin_user"
}

resource "null_resource" "restapi_password" {
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/restapi_password' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "restapi_password" {
  depends_on = [null_resource.restapi_password]
  name       = "/${var.customer}/${var.env}/restapi_password"
}

# Password for "SSL keystore (used for oracle for now)"
resource "null_resource" "db_ssl_keystore_config" {
  provisioner "local-exec" {
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/db_ssl_keystore_config' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "db_ssl_keystore_pwd" {
  depends_on = [null_resource.db_ssl_keystore_config]
  name       = "/${var.customer}/${var.env}/db_ssl_keystore_config"
}

resource "aws_ssm_parameter" "filefolder_kms_key_id" {
  name   = "/${var.customer}/${var.env}/filefolder_kms_key_id"
  type   = "SecureString"
  value  = var.enable_byok == "false" ? aws_kms_key.a[0].id : data.aws_kms_alias.default_s3_ff_fortanix_key[0].target_key_id
  key_id = var.enable_byok == "false" ? aws_kms_key.ssm.id : data.aws_kms_alias.default_s3_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "filefolder_access_key_id" {
  name   = "/${var.customer}/${var.env}/filefolder_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.id
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "filefolder_secret_access_key" {
  name   = "/${var.customer}/${var.env}/filefolder_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.secret
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "archive_filefolder_kms_key_id" {
  name   = "/${var.customer}/${var.env}/archive_filefolder_kms_key_id"
  type   = "SecureString"
  value  = var.enable_byok == "false" ? aws_kms_key.archive_ff[0].id : data.aws_kms_alias.archive_ff_fortanix_key[0].target_key_id
  key_id = var.enable_byok == "false" ? aws_kms_key.archive_ff[0].id : data.aws_kms_alias.archive_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "archive_filefolder_access_key_id" {
  name   = "/${var.customer}/${var.env}/archive_filefolder_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.id
  key_id = var.enable_byok == "false" ? aws_kms_key.archive_ff[0].id : data.aws_kms_alias.archive_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "archive_filefolder_secret_access_key" {
  name   = "/${var.customer}/${var.env}/archive_filefolder_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.secret
  key_id = var.enable_byok == "false" ? aws_kms_key.archive_ff[0].id : data.aws_kms_alias.archive_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "worm_filefolder_kms_key_id" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/worm_filefolder_kms_key_id"
  type   = "SecureString"
  value  = var.enable_byok == "false" ? aws_kms_key.worm_bucket[count.index].id : data.aws_kms_alias.worm_bucket_fortanix_key[0].target_key_id
  key_id = var.enable_byok == "false" ? aws_kms_key.worm_bucket[count.index].id : data.aws_kms_alias.worm_bucket_fortanix_key[0].name
}

resource "aws_ssm_parameter" "worm_filefolder_access_key_id" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/worm_filefolder_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.id
  key_id = var.enable_byok == "false" ? aws_kms_key.worm_bucket[count.index].id : data.aws_kms_alias.worm_bucket_fortanix_key[0].name
}

resource "aws_ssm_parameter" "worm_filefolder_secret_access_key" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/worm_filefolder_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.secret
  key_id = var.enable_byok == "false" ? aws_kms_key.worm_bucket[count.index].id : data.aws_kms_alias.worm_bucket_fortanix_key[0].name
}

resource "aws_ssm_parameter" "email_access_key_id" {
  name   = "/${var.customer}/${var.env}/email_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.email.id
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "email_secret_access_key" {
  name   = "/${var.customer}/${var.env}/email_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.email.ses_smtp_password_v4
  key_id = aws_kms_key.ssm.id
}

# S3 uploader
resource "aws_ssm_parameter" "s3uploader_access_key_id" {
  name   = "/${var.customer}/${var.env}/s3uploader_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.s3uploader.id
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "s3uploader_secret_access_key" {
  name   = "/${var.customer}/${var.env}/s3uploader_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.s3uploader.secret
  key_id = aws_kms_key.ssm.id
}

# outbound transfer
resource "aws_ssm_parameter" "outbound_transfer_access_key_id" {
  count  = var.enable_outbound_transfer == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/outbound_transfer_access_key_id"
  type   = "SecureString"
  value  = join("", aws_iam_access_key.outbound-transfer.*.id)
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "outbound_transfer_secret_access_key" {
  count  = var.enable_outbound_transfer == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/outbound_transfer_secret_access_key"
  type   = "SecureString"
  value  = join("", aws_iam_access_key.outbound-transfer.*.secret)
  key_id = aws_kms_key.ssm.id
}

#generate workspaces AD Admin password
resource "null_resource" "workspace_ad_admin_password" {
  #always generate to allow module variable to be instantiated properly
  provisioner "local-exec" {
    environment = {
      customer = var.customer
      env      = var.env
    }
    command = "python3 scripts/axcli ssm-generate-password --paramname '/${var.customer}/${var.env}/workspace_ad_admin_password' --kms_key_id='${aws_kms_key.ssm.id}'"
  }
}

data "aws_ssm_parameter" "workspace_ad_admin_password" {
  depends_on = [null_resource.workspace_ad_admin_password]
  name       = "/${var.customer}/${var.env}/workspace_ad_admin_password"
}

resource "aws_ssm_parameter" "pgp_filefolder_kms_key_id" {
  count  = var.enable_pgp == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/pgp_filefolder_kms_key_id"
  type   = "SecureString"
  value  = var.enable_byok == "false" ? aws_kms_key.pgp_ff[0].id : data.aws_kms_alias.pgp_fortanix_key[0].target_key_id
  key_id = var.enable_byok == "false" ? aws_kms_key.pgp_ff[0].id : data.aws_kms_alias.pgp_fortanix_key[0].name
}

resource "aws_ssm_parameter" "reporting_files_filefolder_kms_key_id" {
  name   = "/${var.customer}/${var.env}/reporting_files_filefolder_kms_key_id"
  type   = "SecureString"
  value  = var.enable_byok == "false" ? aws_kms_key.reporting_files_ff[0].id : data.aws_kms_alias.reporting_files_ff_fortanix_key[0].target_key_id
  key_id = var.enable_byok == "false" ? aws_kms_key.reporting_files_ff[0].id : data.aws_kms_alias.reporting_files_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "reporting_files_filefolder_access_key_id" {
  name   = "/${var.customer}/${var.env}/reporting_files_filefolder_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.id
  key_id = var.enable_byok == "false" ? aws_kms_key.reporting_files_ff[0].id : data.aws_kms_alias.reporting_files_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "reporting_files_filefolder_secret_access_key" {
  name   = "/${var.customer}/${var.env}/reporting_files_filefolder_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.filefolder.secret
  key_id = var.enable_byok == "false" ? aws_kms_key.reporting_files_ff[0].id : data.aws_kms_alias.reporting_files_ff_fortanix_key[0].name
}

resource "aws_ssm_parameter" "emr_execution_staging_kms_key_id" {
  count  = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/execution_staging_kms_key_id"
  type   = "SecureString"
  value  = aws_kms_key.emr_staging[0].id
  key_id = aws_kms_key.ssm.id
}

# currently set to hive at directives of spark team
resource "aws_ssm_parameter" "spark_hive_password" {
  count  = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/spark_hive_password"
  type   = "SecureString"
  value  = "hive"
  key_id = aws_kms_key.ssm.id
}

data "aws_ssm_parameter" "webproxy_password" {
  count    = var.enable_webproxy == "true" ? 1 : 0
  provider = aws.sst
  name     = "/web-proxy-${var.jenkins_env_short}-${var.aws_region}/squid-secrets/${var.webproxy_username}"
}

resource "aws_ssm_parameter" "webproxy_password" {
  count     = var.enable_webproxy == "true" ? 1 : 0
  name      = "/${var.customer}/${var.env}/webproxy/webproxy_password"
  type      = "SecureString"
  value     = data.aws_ssm_parameter.webproxy_password[count.index].value
  key_id    = aws_kms_key.ssm.id
  overwrite = "true"
}

resource "aws_ssm_parameter" "webproxy_username" {
  count     = var.enable_webproxy == "true" ? 1 : 0
  name      = "/${var.customer}/${var.env}/webproxy/webproxy_username"
  type      = "String"
  value     = var.webproxy_username
  key_id    = aws_kms_key.ssm.id
  overwrite = "true"
}

# SFTP user
resource "aws_ssm_parameter" "sftp_access_key_id" {
  count  = var.enable_sftp_transfer == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/sftp_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.sftptransfer[0].id
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "sftp_secret_access_key" {
  count  = var.enable_sftp_transfer == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/sftp_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.sftptransfer[0].secret
  key_id = aws_kms_key.ssm.id
}

# Monitoring user
resource "aws_ssm_parameter" "monitoring_access_key_id" {
  name   = "/${var.customer}/${var.env}/monitoring_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.monitoring.id
  key_id = aws_kms_key.ssm.id
}

resource "aws_ssm_parameter" "monitoring_secret_access_key" {
  name   = "/${var.customer}/${var.env}/monitoring_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.monitoring.secret
  key_id = aws_kms_key.ssm.id
}
