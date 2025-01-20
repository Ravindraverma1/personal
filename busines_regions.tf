variable "business_region" {
  type = map(string)

  default = {
    eu-west-1      = "EMEA"
    eu-west-2      = "EMEA"
    eu-central-1   = "EMEA"
    us-east-1      = "AMER"
    us-east-2      = "AMER"
    us-west-1      = "AMER"
    us-west-2      = "AMER"
    ap-southeast-1 = "APAC"
    ap-southeast-2 = "APAC"
    ap-northeast-1 = "APAC"
    ap-northeast-2 = "APAC"
    ap-south-1     = "APAC"
    sa-east-1      = "APAC"
  }
}

