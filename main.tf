provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.env_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

provider "aws" {
  alias                   = "sst"
  region                  = var.aws_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.sst_aws_profile
  version                 = "~> 3.74.1"
}

provider "aws" {
  alias                   = "peer"
  region                  = var.elk_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.sst_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

provider "aws" {
  alias                   = "ha-proxy-peer"
  region                  = var.ha_proxy_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.sst_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

# A separate AWS provider in us-east-1 is required for subscribing to Amazon IP change for SES
# Topic arn: arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged
provider "aws" {
  alias                   = "ip-range-changes"
  region                  = "us-east-1"
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.env_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

# AWS provider on resources owner
provider "aws" {
  alias                   = "vpnowner"
  region                  = var.aws_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.vpnowner_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

# AWS provider on citrixservices account
# citrixservices_region currently set to eu-west-1
provider "aws" {
  alias                   = "citrixservices"
  region                  = var.citrixservices_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = "citrixservices"
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

data "terraform_remote_state" "axiom" {
  backend = "s3"
  config = {
    bucket  = var.tfstate_bucket_name
    key     = "status/terraform.tfstate"
    region  = var.aws_region
    profile = var.env_aws_profile
    encrypt = true
  }
}

provider "aws" {
  alias                   = "occ-sst"
  region                  = var.occ_sns_topic_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.sst_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

provider "aws" {
  alias                   = "occ-sns-cust"
  region                  = var.occ_sns_topic_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.env_aws_profile
  version                 = "~> 3.74.1"
  default_tags { tags = { "${var.map_tag_key}" = "${var.map_tag_value}" } }
}

/* # disable this for now. It causes an error where multi regions are used (like in UAT).
   # account-terraform bucket is created in 1 region and being referred to by another region, causing error.
data "terraform_remote_state" "tfstate_account" {
  backend = "s3"
  config {
    bucket  = "axiom-${data.aws_caller_identity.env_account.account_id}-account-terraform"
    key     = "status/terraform.tfstate"
    region  = "${var.aws_region}"
    profile = "${var.env_aws_profile}"
    encrypt = true
  }
}
*/

provider "aws" {
  alias                   = "sst_web_proxy"
  region                  = var.mft_app_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.sst_aws_profile
  version                 = "~> 3.74.1"
}
