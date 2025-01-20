resource "aws_iam_user" "s3uploader" {
  name = "${var.customer}-${var.env}-s3uploader-user"
  path = "/"
}

resource "aws_iam_user" "email" {
  name = "${var.customer}-${var.env}-email-user"
  path = "/"
}

#to be deprecated from IaC 1.39
resource "aws_iam_user" "filefolder" {
  name = "${var.customer}-${var.env}-filefolder-user"
  path = "/"
}

resource "aws_iam_user" "outbound-transfer" {
  count = var.enable_outbound_transfer == "true" ? 1 : 0
  name  = "${var.customer}-${var.env}-outbound-transfer-user"
  path  = "/"
}

resource "aws_iam_access_key" "s3uploader" {
  user = aws_iam_user.s3uploader.name
}

resource "aws_iam_access_key" "email" {
  user = aws_iam_user.email.name
}

#to be deprecated from IaC 1.39
resource "aws_iam_access_key" "filefolder" {
  user = aws_iam_user.filefolder.name
}

resource "aws_iam_access_key" "outbound-transfer" {
  count = var.enable_outbound_transfer == "true" ? 1 : 0
  user  = aws_iam_user.outbound-transfer[0].name
}

resource "aws_iam_group" "customers" {
  name = "${var.customer}-${var.env}-Customers"
  path = "/"
}

resource "aws_iam_group" "emailsenders" {
  name = "${var.customer}-${var.env}-EmailSenders"
  path = "/"
}

#to be deprecated from IaC 1.39
resource "aws_iam_group" "filefolderadmins" {
  name = "${var.customer}-${var.env}-FileFoldersAdmin"
  path = "/"
}

resource "aws_iam_group" "outboundtransfer" {
  count = var.enable_outbound_transfer == "true" ? 1 : 0
  name  = "${var.customer}-${var.env}-OutboundTransfer"
  path  = "/"
}

resource "aws_iam_group_membership" "customers" {
  name = "Customer-group-membership"
  users = [
    aws_iam_user.s3uploader.name,
  ]
  group = aws_iam_group.customers.name
}

resource "aws_iam_group_membership" "emailsenders" {
  name = "EmailSenders-group-membership"
  users = [
    aws_iam_user.email.name,
  ]
  group = aws_iam_group.emailsenders.name
}

#to be deprecated from IaC 1.39
resource "aws_iam_group_membership" "filefolderadmins" {
  name = "FileFolderAdmins-group-membership"
  users = [
    aws_iam_user.filefolder.name,
  ]
  group = aws_iam_group.filefolderadmins.name
}

resource "aws_iam_group_membership" "outboundtransfer" {
  count = var.enable_outbound_transfer == "true" ? 1 : 0
  name  = "OutboundTransfer-group-membership"
  users = [
    aws_iam_user.outbound-transfer[0].name,
  ]
  group = aws_iam_group.outboundtransfer[0].name
}

resource "aws_iam_user" "sftptransfer" {
  count = var.enable_sftp_transfer == "true" ? 1 : 0
  name = "${var.customer}-${var.env}-sftp-user"
  path = "/"
}

resource "aws_iam_access_key" "sftptransfer" {
  count = var.enable_sftp_transfer == "true" ? 1 : 0
  user  = aws_iam_user.sftptransfer[0].name
}

resource "aws_iam_group" "sftptransfer" {
  count = var.enable_sftp_transfer == "true" ? 1 : 0
  name = "${var.customer}-${var.env}-SFTP-Transfer"
  path = "/"
}

resource "aws_iam_group_membership" "sftptransfer" {
  count = var.enable_sftp_transfer == "true" ? 1 : 0
  name = "SFTP-Transfer-group-membership"
  users = [
    aws_iam_user.sftptransfer[0].name,
  ]
  group = aws_iam_group.sftptransfer[0].name
}

#Monitoring user
resource "aws_iam_user" "monitoring" {
  name = "${var.customer}-${var.env}-monitoring-user"
  path = "/"
}

resource "aws_iam_access_key" "monitoring" {
  user  = aws_iam_user.monitoring.name
}

resource "aws_iam_group" "monitoring" {
  name = "${var.customer}-${var.env}-Monitoring"
  path = "/"
}

resource "aws_iam_group_membership" "monitoring" {
  name = "Monitoring-group-membership"
  users = [
    aws_iam_user.monitoring.name,
  ]
  group = aws_iam_group.monitoring.name
}