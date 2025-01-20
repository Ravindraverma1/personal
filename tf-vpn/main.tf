provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${pathexpand("~/.aws/credentials")}"
  profile                 = "${var.env_aws_profile}"
  version                 = "<= 2.60.0"
}
# AWS provider on resources owner
provider "aws" {
  alias                   = "vpnowner"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${pathexpand("~/.aws/credentials")}"
  profile                 = "${var.vpnowner_aws_profile}"
  version                 = "<= 2.60.0"
}

provider "awsvpn" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${pathexpand("~/.aws/credentials")}"
  profile                 = "${var.env_aws_profile}"
}
