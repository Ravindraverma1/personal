#########################################################
# Terraform Backend to store status in S3               #
# Variables will be replaced by initialize-terraform.sh #
#########################################################
terraform {
  backend "s3" {
    bucket  = "${tfstate_bucket_name}"
    key     = "status/terraform${tf_resource_type}.tfstate"
    region  = "${aws_region}"
    profile = "${env_aws_profile}"
    encrypt = true
  }
}