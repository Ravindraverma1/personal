resource "aws_network_acl" "network_acl_3az" {
  count = var.use_2az == "0" ? 1 : 0
  subnet_ids = [
    aws_subnet.data_a.id,
    aws_subnet.data_b.id,
    element(concat(aws_subnet.data_c.*.id, [""]), 0),
    aws_subnet.front_b.id,
    aws_subnet.front_a.id,
    aws_subnet.front_gateway_a.id,
    aws_subnet.front_gateway_b.id,
  ]
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl" "network_acl" {
  count = var.use_2az == "1" ? 1 : 0
  subnet_ids = [
    aws_subnet.data_a.id,
    aws_subnet.data_b.id,
    aws_subnet.front_b.id,
    aws_subnet.front_a.id,
    aws_subnet.front_gateway_a.id,
    aws_subnet.front_gateway_b.id,
  ]
  vpc_id = aws_vpc.main.id
}

# App tier Network ACL
resource "aws_network_acl" "network_acl_app" {
  subnet_ids = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id,
  ]
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_rule" "nacl_rule_https" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "210"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ssh" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "220"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "nacl_rule_internal_in" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "230"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_https_outbound" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "300"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path_outbound" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "310"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_internal_out" {
  count          = var.use_2az == "1" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "320"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ldaps_out" {
  count          = var.use_2az == "1" && var.customer_ldap_ip != "" && var.customer_ldap_ip != " " ? 1 : 0
  network_acl_id = aws_network_acl.network_acl[0].id
  rule_number    = "340"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.customer_ldap_ip}/32"
  from_port      = 636
  to_port        = 636
}

# for 3 availability zones reference
resource "aws_network_acl_rule" "nacl_rule_https_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "210"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ssh_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "220"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "nacl_rule_internal_in_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "230"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_https_outbound_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "300"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path_outbound_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "310"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_internal_out_3az" {
  count          = var.use_2az == "0" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "320"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ldaps_out_3az" {
  count          = var.use_2az == "0" && var.customer_ldap_ip != "" && var.customer_ldap_ip != " " ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_3az[0].id
  rule_number    = "340"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.customer_ldap_ip}/32"
  from_port      = 636
  to_port        = 636
}

# App tier Network ACL
resource "aws_network_acl_rule" "nacl_rule_https_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "200"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "210"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ssh_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "220"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "nacl_rule_internal_in_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "230"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_https_outbound_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "300"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "nacl_rule_return_path_outbound_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "310"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_internal_out_app" {
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "320"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.internal_cidr_start1}.0/23"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "nacl_rule_ldaps_out_app" {
  count          = var.customer_ldap_ip != "" && var.customer_ldap_ip != " " ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_app.id
  rule_number    = "340"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.customer_ldap_ip}/32"
  from_port      = 636
  to_port        = 636
}

resource "aws_network_acl_rule" "nacl_rule_oci_in_app" {
  count          = var.enable_oci_db == "true" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_app.id
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 240
  cidr_block     = var.vcn_cidr
  egress         = false
  from_port      = var.oci_db_port
  to_port        = var.oci_db_port
}

resource "aws_network_acl_rule" "nacl_rule_oci_out_app" {
  count          = var.enable_oci_db == "true" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_app.id
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 350
  cidr_block     = var.vcn_cidr
  egress         = true
  from_port      = var.oci_db_port
  to_port        = var.oci_db_port
}

resource "aws_network_acl_rule" "nacl_rule_http_in_app" {
  count          = var.enable_spark == "true" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_app.id
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 250
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "nacl_rule_http_out_app" {
  count          = var.enable_spark == "true" ? 1 : 0
  network_acl_id = aws_network_acl.network_acl_app.id
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 360
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 80
  to_port        = 80
}
