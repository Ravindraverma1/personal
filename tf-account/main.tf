provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.env_aws_profile
  version                 = "~> 3.74.1"
}
