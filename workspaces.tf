#invoke workspaces module
module "ax_workspaces" {
  source                    = "./modules/terraform-aws-workspaces"
  account_id                = data.aws_caller_identity.env_account.account_id
  customer                  = var.customer
  env                       = var.env
  cust_region               = var.aws_region
  business_region           = var.business_region
  aws_ds_domain_name        = var.axcloud_domain
  enable_workspaces         = var.enable_workspaces
  aws_managed_directory     = var.aws_managed_directory
  cust_vpc_id               = aws_vpc.main.id
  cust_vpc_cidr             = aws_vpc.main.cidr_block
  cust_nat_gw_id            = aws_nat_gateway.nat_gw1a.id
  cust_intrnt_gw_id         = aws_internet_gateway.internet_gw.id
  cust_vpc_sec_cidr1        = var.internal_sec_cidr_start1
  cust_vpc_sec_cidr2        = var.internal_sec_cidr_start2
  front_nlb_security_grp_id = aws_security_group.elb_front_nginx.id
  aws_managed_ad_type       = var.aws_managed_ad_type
  aws_managed_ad_edition    = var.aws_managed_ad_edition
  aws_ad_admin_password     = data.aws_ssm_parameter.workspace_ad_admin_password.value
  workspace_bundle_id       = var.workspace_bundle_id
  user_workspaces           = var.user_workspaces
}

