# Create the DHCP options
resource "aws_vpc_dhcp_options" "internal-zone" {
  domain_name         = "${var.customer}-${var.env}.axiom"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name         = "${var.aws_region}-${var.customer}-${var.env}-dopt-${var.env}"
    region       = var.business_region[var.aws_region]
    customer     = var.customer
    instancerole = "dhcp_option_set"
  }
}

# Assosiate the DHCP options with the VPC
resource "aws_vpc_dhcp_options_association" "dopt-vpc" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.internal-zone.id
}

