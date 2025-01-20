# Some of the security groups are created using `aws_security_group` resource with embedded rules
# and some are created using empty `aws_security_group` with rules specified as `aws_security_group_rule`
# this is intentional. It was introduced to avoid terraform error with discovering a cycle when two
# SGs are referring to each other - like NGINX ELB and NGINX SGs.
##
#  bastion
##
resource "aws_security_group" "bastion" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-bastion"
  vpc_id      = aws_vpc.main.id
  description = "Bastion server security group."

  ingress {
    description = "Allows SSH access to whitelisted CIDRs."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.source_cidr_blocks_allowed
  }

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-bastion"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "bastion_egress_0" {
  description              = "Allows outbound SSH traffic to VPC range."
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssh_from_bastion.id
  security_group_id        = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_1" {
  description       = "Allows outbound traffic to S3 and SSM endpoints."
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_2" {
  description              = "Allows outbound traffic to cloudwatch endpoint."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_3" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "Allows outbound traffic to Spark external-execution-gateway"
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.exe_emr_cluster.master_security_group_id
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_4" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "Allows outbound traffic to Spark external-execution-hive"
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.thrift_emr_cluster.master_security_group_id
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group" "ssh_from_bastion" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-ssh_from_bastion"
  description = "SSH from bastion security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-ssh_from_bastion"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "ssh_from_bastion_ingress_1" {
  type                     = "ingress"
  description              = "Allows inbound traffic from bastion ec2 to CVaaS instances"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ssh_from_bastion.id
  source_security_group_id = aws_security_group.bastion.id
}

##
#  nginx_front_elb
##
resource "aws_security_group" "elb_front_nginx" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-elb_front_nginx"
  description = "NGINX front ELB security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-elb_front_nginx"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "elb_front_nginx_ingress_0" {
  count             = var.enable_vpn_access == "true" ? 0 : 1
  description       = "Allow HTTPS inbound traffic from outside world to front NGINX ELB."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks_allowed
  security_group_id = aws_security_group.elb_front_nginx.id
}

resource "aws_security_group_rule" "elb_front_nginx_ingress_1" {
  count             = var.enable_vpn_access == "true" ? 1 : 0
  description       = "Allow HTTPS inbound traffic from front internal NLB to front NGINX ELB."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.front_b.cidr_block, aws_subnet.front_a.cidr_block] # grant ingress for subnets where front NLB resides
  security_group_id = aws_security_group.elb_front_nginx.id
}
###
# Citrix connection forward NLB
###
resource "aws_security_group_rule" "elb_front_nginx_ingress_2" {
  count             = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  description       = "Allow HTTPS inbound traffic from front internal NLB to front NGINX ELB."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.front_b.cidr_block, aws_subnet.front_a.cidr_block] # grant ingress for subnets where front NLB resides
  security_group_id = aws_security_group.elb_front_nginx.id
}
###

resource "aws_security_group_rule" "elb_front_nginx_ingress_3" {
  count             = var.enable_citrixservices ? 1 : 0
  description       = "Allow HTTPS inbound traffic from Citrix VPC to front NGINX ELB."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.citrixservices_vpc_cidr_block]
  security_group_id = aws_security_group.elb_front_nginx.id
}


resource "aws_security_group_rule" "elb_front_nginx_egress_0" {
  description              = "Allow HTTPS outbound traffic from ELB to NGINX servers."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx.id
  security_group_id        = aws_security_group.elb_front_nginx.id
}


##
#  nginx_int_elb
##
resource "aws_security_group" "elb_internal_nginx" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_nginx"
  description = "NGINX internal ELB security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_nginx"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "elb_internal_nginx_ingress_1" {
  description              = "Allow HTTPS inbound traffic from CV REST API Lambda"
  type                     = "ingress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_security_group.id
  security_group_id        = aws_security_group.elb_internal_nginx.id
}

resource "aws_security_group_rule" "elb_internal_nginx_ingress_2" {
  description              = "Allow HTTPS inbound traffic from CV REST API Lambda"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_security_group.id
  security_group_id        = aws_security_group.elb_internal_nginx.id
}

resource "aws_security_group_rule" "elb_internal_nginx_egress_0" {
  description              = "Allow HTTPS outbound traffic from elb-internal-nginx to NGINX servers."
  type                     = "egress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx.id
  security_group_id        = aws_security_group.elb_internal_nginx.id
}

##
#  NGINX
##
resource "aws_security_group" "nginx" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-nginx"
  description = "NGINX EC2 instances security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-nginx"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "nginx_ingress_0" {
  description              = "Allows inbound traffic from ELB to NGINX servers."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_front_nginx.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_ingress_1" {
  description              = "Allows inbound traffic from ELB NGINX internal to NGINX servers."
  type                     = "ingress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_internal_nginx.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_ingress_2" {
  description              = "Allows inbound traffic from ELB CV internal to NGINX servers."
  type                     = "ingress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_ingress_3" {
  description              = "Allows inbound traffic from Lambda SSH to run commands."
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_ssh_security_group.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_0" {
  description              = "Allows outbound traffic from NGINX servers to TOMCAT ELB."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_internal_tomcat.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_1" {
  description              = "Allows outbound traffic from NGINX to outside world."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_2" {
  description       = "Allows outbound traffic to S3 endpoint."
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_3" {
  description              = "Allows outbound traffic to CV internal elb."
  type                     = "egress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_4" {
  description              = "Allows outbound traffic to cloudwatch endpoint."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_5" {
  description       = "Allows outbound traffic to ELK endpoint."
  type              = "egress"
  from_port         = element(split(":", var.logstash_host), 1)
  to_port           = element(split(":", var.logstash_host), 1)
  protocol          = "tcp"
  cidr_blocks       = [var.elk_subnet]
  security_group_id = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_6" {
  description       = "Allows outbound traffic to HAPROXY endpoint."
  type              = "egress"
  from_port         = var.dd_proxy_port
  to_port           = var.dd_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "nginx_egress_7" {
  description       = "Allows outbound traffic to Logz.io HAPROXY endpoint for Logs."
  type              = "egress"
  from_port         = var.logs_logzio_port
  to_port           = var.logs_logzio_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.nginx.id
}

##
#  tc_int_elb
##
resource "aws_security_group" "elb_internal_tomcat" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_tomcat"
  description = "Tomcat internal ELB security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_tomcat"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "elb_internal_tomcat_ingress_0" {
  description              = "Allows inbound traffic from NGINX to TOMCAT ELB."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx.id
  security_group_id        = aws_security_group.elb_internal_tomcat.id
}

resource "aws_security_group_rule" "elb_internal_tomcat_ingress_2" {
  description              = "Allows inbound traffic from CV to TOMCAT ELB."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.elb_internal_tomcat.id
}

resource "aws_security_group_rule" "elb_internal_tomcat_egress_0" {
  description              = "Allows outbound traffic from ELB internal to TOMCAT servers."
  type                     = "egress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.elb_internal_tomcat.id
}

######################
# Internal ELB for CV
######################
resource "aws_security_group" "elb_internal_cv" {
  count       = 0
  name        = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_cv"
  description = "CV internal ELB security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-elb_internal_cv"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "elb_internal_cv_ingress_0" {
  count                    = 0
  description              = "Allows inbound traffic from TOMCAT to CV ELB."
  type                     = "ingress"
  from_port                = 9999
  to_port                  = 9999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_ingress_1" {
  count                    = 0
  description              = "Allows inbound healthcheck traffic from TOMCAT to CV ELB."
  type                     = "ingress"
  from_port                = 8100
  to_port                  = 8100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_ingress_2" {
  count                    = 0
  description              = "Allows inbound traffic from NGINX to CV ELB."
  type                     = "ingress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_ingress_3" {
  count                    = 0
  description              = "Allows inbound traffic from TOMCAT to CV logstash."
  type                     = "ingress"
  from_port                = 5044
  to_port                  = 5044
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_egress_0" {
  count                    = 0
  description              = "Allows outbound traffic from ELB internal to CV servers."
  type                     = "egress"
  from_port                = 9999
  to_port                  = 9999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_egress_1" {
  count                    = 0
  description              = "Allows outbound healthcheck traffic from ELB internal to CV servers."
  type                     = "egress"
  from_port                = 8100
  to_port                  = 8100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_egress_2" {
  count                    = 0
  description              = "Allows outbound Nginx traffic from ELB internal to CV servers."
  type                     = "egress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

resource "aws_security_group_rule" "elb_internal_cv_egress_3" {
  count                    = 0
  description              = "Allows outbound logstash traffic from ELB internal to CV servers."
  type                     = "egress"
  from_port                = 5044
  to_port                  = 5044
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.elb_internal_cv[0].id
}

##
#  CV
##
resource "aws_security_group" "cv" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-cv"
  vpc_id      = aws_vpc.main.id
  description = "CV servers security group."

  ingress {
    description     = "Allows inbound traffic from tomcat to CV server via internal elb."
    from_port       = 9999
    protocol        = "tcp"
    to_port         = 9999
    security_groups = [aws_security_group.tomcat.id]
  }

  ingress {
    description     = "Allows inbound traffic from NGINX to CV server via internal elb."
    from_port       = 8089
    protocol        = "tcp"
    to_port         = 8089
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    description     = "Allows inbound traffic from tomcat to CV server via internal elb."
    from_port       = 8100
    protocol        = "tcp"
    to_port         = 8100
    security_groups = [aws_security_group.tomcat.id]
  }

  ingress {
    description     = "Allows inbound traffic from Lambda SSH to run commands."
    from_port       = 22
    protocol        = "tcp"
    to_port         = 22
    security_groups = [aws_security_group.lambda_ssh_security_group.id]
  }

  ingress {
    description     = "Allows inbound traffic from tomcat to CV logstash server via internal elb."
    from_port       = 5044
    protocol        = "tcp"
    to_port         = 5044
    security_groups = [aws_security_group.tomcat.id]
  }

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-cv"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "cv_egress_0" {
  description = "Allows outbound traffic from CV server to RDS."
  type        = "egress"

  #from_port                = "${lookup(var.db_port, var.db_parameter_group_family)}"
  from_port = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]

  #to_port                  = "${lookup(var.db_port, var.db_parameter_group_family)}"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds-sg.id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_1" {
  description              = "Allows outbound traffic to EFS."
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_2" {
  description              = "Allows outbound traffic to S3 and SSM endpoints."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  prefix_list_ids          = [aws_vpc_endpoint.s3.prefix_list_id]
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_3" {
  description       = "Allows outbound traffic to ELK endpoint."
  type              = "egress"
  from_port         = element(split(":", var.logstash_host), 1)
  to_port           = element(split(":", var.logstash_host), 1)
  protocol          = "tcp"
  cidr_blocks       = [var.elk_subnet]
  security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_4" {
  description       = "Allows outbound traffic to HAPROXY endpoint."
  type              = "egress"
  from_port         = var.dd_proxy_port
  to_port           = var.dd_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.cv.id
}

#TC ELB to access CV host
resource "aws_security_group_rule" "cv_egress_5" {
  description              = "Allows outbound traffic from TC ELB internal to CV servers."
  type                     = "egress"
  from_port                = 9999
  to_port                  = 9999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_6" {
  count             = var.customer_ldap_ip != " " && var.customer_ldap_ip != "" ? 1 : 0
  description       = "Allows outbound traffic from CV to LDAPS IP"
  type              = "egress"
  from_port         = 636
  to_port           = 636
  protocol          = "tcp"
  cidr_blocks       = ["${var.customer_ldap_ip}/32"]
  security_group_id = aws_security_group.cv.id
}

# Redshift
resource "aws_security_group_rule" "cv_egress_7" {
  count                    = var.enable_redshift == "true" ? 1 : 0
  description              = "Outbound traffic from CV to Redshift cluster"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cv.id
  to_port                  = var.cluster_port
  type                     = "egress"
  source_security_group_id = aws_security_group.redshift_sg.id
}

resource "aws_security_group_rule" "cv_egress_8" {
  description              = "Allows outbound traffic from TC ELB internal to CV logstash."
  type                     = "egress"
  from_port                = 5044
  to_port                  = 5044
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_9" {
  count             = var.use_datascope_refinitiv == "true" ? 1 : 0
  description       = "Allows outbound traffic to HAPROXY endpoint (Refinitiv)."
  type              = "egress"
  from_port         = var.refinitiv_proxy_port
  to_port           = var.refinitiv_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_10" {
  description              = "Allows outbound traffic to SMTP endpoints."
  type                     = "egress"
  from_port                = 587
  to_port                  = 587
  protocol                 = "tcp"
  prefix_list_ids          = [aws_vpc_endpoint.s3.prefix_list_id]
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id        = aws_security_group.cv.id
}

# Snowflake
resource "aws_security_group_rule" "cv_egress_11" {
  count                    = var.enable_snowflake == "true" ? 1 : 0
  description              = "Allows outbound 443 traffic to Snowflake endpoint."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.snowflake[0].id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_12" {
  count                    = var.enable_snowflake == "true" ? 1 : 0
  description              = "Allows outbound 80 traffic to Snowflake endpoint."
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.snowflake[0].id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_13" {
  description       = "Allows outbound traffic to Datadog API HAPROXY endpoint for Application Metrics."
  type              = "egress"
  from_port         = var.app_metrics_dd_proxy_port
  to_port           = var.app_metrics_dd_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_14" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "cv outbound traffic to RabbitMQ."
  type                     = "egress"
  from_port                = var.mq_broker_port
  to_port                  = var.mq_broker_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mq_broker[0].id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_15" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "cv outbound http traffic to execution emr gateway"
  type                     = "egress"
  from_port                = var.gateway_listener_port
  to_port                  = var.gateway_listener_port
  protocol                 = "tcp"
  source_security_group_id = module.exe_emr_cluster.master_security_group_id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_16" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "cv outbound traffic to Hive listener."
  type                     = "egress"
  from_port                = var.hive_listener_port
  to_port                  = var.hive_listener_port
  protocol                 = "tcp"
  source_security_group_id = module.thrift_emr_cluster.master_security_group_id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_17" {
  count             = var.enable_app_metrics_monitoring == "true" ? 1 : 0
  description       = "Allows outbound traffic to Logz.io HAPROXY endpoint for Application Metrics."
  type              = "egress"
  from_port         = var.app_metrics_logzio_port
  to_port           = var.app_metrics_logzio_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_18" {
  description       = "Allows outbound traffic to Logz.io HAPROXY endpoint for Logs."
  type              = "egress"
  from_port         = var.logs_logzio_port
  to_port           = var.logs_logzio_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_19" {
  count                    = var.enable_webproxy == "true" ? 1 : 0
  description              = "Allows outbound traffic to web-proxy endpoint"
  type                     = "egress"
  from_port                = var.webproxy_port
  to_port                  = var.webproxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webproxy[0].id
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_20" {
  count                    = var.enable_vpn_access == "true" && var.use_transit_gateway == "true" && var.enable_mvt_access == "true" ? 1 : 0
  description              = "Allows outbound traffic to CV9 env server IP"
  type                     = "egress"
  from_port                = var.target_cv9_env_server_port
  to_port                  = var.target_cv9_env_server_port
  protocol                 = "tcp"
  cidr_blocks              = ["${var.target_cv9_env_server_ip}/32"]
  security_group_id        = aws_security_group.cv.id
}

resource "aws_security_group_rule" "cv_egress_21" {
  count                    = var.enable_vpn_access == "true" && var.use_transit_gateway == "true" && var.enable_mvt_access == "true" ? 1 : 0
  description              = "Allows outbound traffic to CV9 env DB IP"
  type                     = "egress"
  from_port                = var.target_cv9_env_db_port
  to_port                  = var.target_cv9_env_db_port
  protocol                 = "tcp"
  cidr_blocks              = ["${var.target_cv9_env_db_ip}/32"]
  security_group_id        = aws_security_group.cv.id
}
##
#  Tomcat
##
resource "aws_security_group" "tomcat" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-tomcat"
  vpc_id      = aws_vpc.main.id
  description = "Tomcat servers security group."

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-tomcat"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "tomcat_ingress_0" {
  description              = "Allows inbound trafic from elb-internal-tomcat to TOMCAT servers."
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_internal_tomcat.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_ingress_1" {
  description              = "Allows inbound trafic from elb-internal-tomcat to TOMCAT REST API."
  type                     = "ingress"
  from_port                = 8099
  to_port                  = 8099
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb_internal_tomcat.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_ingress_2" {
  description              = "Allows inbound traffic from Lambda SSH to run commands."
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_ssh_security_group.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_0" {
  description              = "Allows outbound traffic from TOMCAT servers to CV internal elb."
  type                     = "egress"
  from_port                = 9999
  to_port                  = 9999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_1" {
  description              = "Allows outbound traffic to EFS"
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_2" {
  description       = "Allows outbound traffic to S3 endpoint."
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_3" {
  description              = "Allows outbound traffic from TOMCAT servers to CV internal elb."
  type                     = "egress"
  from_port                = 8100
  to_port                  = 8100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_4" {
  description              = "Allows outbound traffic to cloudwatch endpoint."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_5" {
  description       = "Allows outbound traffic to ELK endpoint."
  type              = "egress"
  from_port         = element(split(":", var.logstash_host), 1)
  to_port           = element(split(":", var.logstash_host), 1)
  protocol          = "tcp"
  cidr_blocks       = [var.elk_subnet]
  security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_6" {
  description       = "Allows outbound traffic to HAPROXY endpoint."
  type              = "egress"
  from_port         = var.dd_proxy_port
  to_port           = var.dd_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.tomcat.id
}

# allows tomcat to use its sql client to connect RDS
resource "aws_security_group_rule" "tomcat_egress_7" {
  description = "Allows outbound traffic from Tomcat to RDS."
  type        = "egress"

  #from_port                = "${lookup(var.db_port, var.db_parameter_group_family)}"
  from_port = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]

  #to_port                  = "${lookup(var.db_port, var.db_parameter_group_family)}"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds-sg.id
  security_group_id        = aws_security_group.tomcat.id
}

# Redshift
resource "aws_security_group_rule" "tomcat_egress_8" {
  count                    = var.enable_redshift == "true" ? 1 : 0
  description              = "Outbound traffic from Tomcat to Redshift cluster"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tomcat.id
  to_port                  = var.cluster_port
  type                     = "egress"
  source_security_group_id = aws_security_group.redshift_sg.id
}

resource "aws_security_group_rule" "tomcat_egress_9" {
  description              = "Allows outbound traffic from TOMCAT servers to CV logstash."
  type                     = "egress"
  from_port                = 5044
  to_port                  = 5044
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_10" {
  description              = "Allows outbound traffic to smtp endpoint."
  type                     = "egress"
  from_port                = 587
  to_port                  = 587
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private_endpoints.id
  security_group_id        = aws_security_group.tomcat.id
}

# Snowflake
resource "aws_security_group_rule" "tomcat_egress_11" {
  count                    = var.enable_snowflake == "true" ? 1 : 0
  description              = "Allows outbound 443 traffic to Snowflake endpoint."
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.snowflake[0].id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_12" {
  count                    = var.enable_snowflake == "true" ? 1 : 0
  description              = "Allows outbound 80 traffic to Snowflake endpoint."
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.snowflake[0].id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_13" {
  description       = "Allows outbound traffic to Datadog API HAPROXY endpoint for Application Metrics."
  type              = "egress"
  from_port         = var.app_metrics_dd_proxy_port
  to_port           = var.app_metrics_dd_proxy_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_14" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "tomcat outbound traffic to RabbitMQ."
  type                     = "egress"
  from_port                = var.mq_broker_port
  to_port                  = var.mq_broker_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mq_broker[0].id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_15" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "tomcat outbound http traffic to execution emr gateway"
  type                     = "egress"
  from_port                = var.gateway_listener_port
  to_port                  = var.gateway_listener_port
  protocol                 = "tcp"
  source_security_group_id = module.exe_emr_cluster.master_security_group_id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_16" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "tomcat outbound traffic to Hive listener."
  type                     = "egress"
  from_port                = var.hive_listener_port
  to_port                  = var.hive_listener_port
  protocol                 = "tcp"
  source_security_group_id = module.thrift_emr_cluster.master_security_group_id
  security_group_id        = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_17" {
  count             = var.enable_app_metrics_monitoring == "true" ? 1 : 0
  description       = "Allows outbound traffic to Logz.io HAPROXY endpoint for Application Metrics."
  type              = "egress"
  from_port         = var.app_metrics_logzio_port
  to_port           = var.app_metrics_logzio_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_18" {
  description       = "Allows outbound traffic to Logz.io HAPROXY endpoint for Logs."
  type              = "egress"
  from_port         = var.logs_logzio_port
  to_port           = var.logs_logzio_port
  protocol          = "tcp"
  cidr_blocks       = [var.ha_proxy_subnet]
  security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "tomcat_egress_19" {
  count                    = var.enable_webproxy == "true" ? 1 : 0
  description              = "Allows outbound traffic to web-proxy endpoint"
  type                     = "egress"
  from_port                = var.webproxy_port
  to_port                  = var.webproxy_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webproxy[0].id
  security_group_id        = aws_security_group.tomcat.id
}

##
#  EFS
##
resource "aws_security_group" "efs" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-efs"
  description = "EFS security group."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allows inbound traffic from CV, TOMCAT, and EFS BACKUP instances to EFS."
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.cv.id, aws_security_group.tomcat.id]
  }

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-efs"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group" "private_endpoints" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-private_endpoints"
  description = "private_endpoints security group for aws services."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allows inbound traffic from vpc to aws services private endpoints interfaces."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.internal_cidr_start1}.0/23"]
  }

  ingress {
    description = "Allows inbound traffic from vpc to smtp private endpoints interfaces."
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["${var.internal_cidr_start1}.0/23"]
  }

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-private_endpoints"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

##
# AWS Lambda
##
resource "aws_security_group" "lambda_security_group" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-lambda"
  description = "AWS Lambda security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-lambda"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "lambda_sg_egress_1" {
  description       = "Allows AWS Lambda to reach the internal NGINX elb for CV REST API calls."
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_security_group.id
  to_port           = 443
  type              = "egress"
  cidr_blocks       = [aws_subnet.app_b.cidr_block, aws_subnet.app_a.cidr_block]
}

resource "aws_security_group_rule" "lambda_sg_egress_2" {
  description              = "Allows AWS Lambda to reach the SSM end point."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_security_group.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

resource "aws_security_group_rule" "lambda_sg_egress_3" {
  description       = "Allows Lambda to reach S3 endpoint"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_security_group.id
  to_port           = 443
  type              = "egress"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

# for rollover ecs fargate
resource "aws_security_group" "fargate_security_group" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-fargate"
  description = "AWS Fargate security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-fargate"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "fargate_sg_egress_1" {
  description              = "Allows Fargate task to access Lambda control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fargate_security_group.id
  to_port                  = 443
  type                     = "egress"
  cidr_blocks              = ["0.0.0.0/0"]
}

#  remove inbound and outbound rules into Default Security Group CIS 4.4
##
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}


##
# Separate SG to allow Lambda to run SSH commands
##
resource "aws_security_group" "lambda_ssh_security_group" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-lambda-ssh"
  description = "AWS Lambda SSH security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-lambda-ssh"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "lambda_ssh_sg_egress_1" {
  description       = "Allows Lambda SSH to reach S3 endpoint"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_ssh_security_group.id
  to_port           = 443
  type              = "egress"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

resource "aws_security_group_rule" "lambda_ssh_sg_egress_2" {
  description              = "Allows AWS Lambda SSH to run commands on CV server."
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_ssh_security_group.id
  to_port                  = 22
  type                     = "egress"
  source_security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "lambda_ssh_sg_egress_3" {
  description              = "Allows AWS Lambda SSH to run commands on tomcat server."
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_ssh_security_group.id
  to_port                  = 22
  type                     = "egress"
  source_security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "lambda_ssh_sg_egress_4" {
  description              = "Allows AWS Lambda SSH to run commands on nginx server."
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_ssh_security_group.id
  to_port                  = 22
  type                     = "egress"
  source_security_group_id = aws_security_group.nginx.id
}

# Separate SG to allow Lambda to run sql commands on RDS
##
resource "aws_security_group" "db_usage_lambda_rds_security_group" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-dbusagelambda-rds"
  description = "AWS Lambda rds security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-lambda-rds"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "lambda_rds_sg_egress_1" {
  description = "Allows outbound traffic from Lambda to RDS."
  type        = "egress"

  #from_port                = "${lookup(var.db_port, var.db_parameter_group_family)}"
  from_port = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]

  #to_port                  = "${lookup(var.db_port, var.db_parameter_group_family)}"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds-sg.id
  security_group_id        = aws_security_group.db_usage_lambda_rds_security_group.id
}

resource "aws_security_group_rule" "lambda_rds_sg_egress_2" {
  description              = "Allows run-db-usage-info Lambda to reach the SSM end point."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_usage_lambda_rds_security_group.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

resource "aws_security_group" "service_monitoring_lambda_security_group" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-service-monitoring"
  description = "AWS Lambda service monitoring security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-service-monitoring"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "lambda_svc_mon_egress_1" {
  count       = var.enable_service_monitoring == "true" ? 1 : 0
  description = "Allows outbound traffic from Lambda to RDS."
  type        = "egress"

  #from_port                = "${lookup(var.db_port, var.db_parameter_group_family)}"
  from_port = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]

  #to_port                  = "${lookup(var.db_port, var.db_parameter_group_family)}"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds-sg.id
  security_group_id        = aws_security_group.service_monitoring_lambda_security_group.id
}

resource "aws_security_group_rule" "lambda_svc_mon_egress_2" {
  count             = var.enable_service_monitoring == "true" ? 1 : 0
  description       = "Allows outbound traffic from lambda to invoke other lambda"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.service_monitoring_lambda_security_group.id
}

# OCI access of autonomous databases
resource "aws_security_group" "oci_resources" {
  count       = var.enable_oci_db == "true" ? 1 : 0
  name        = "${var.aws_region}-${var.customer}-${var.env}-oci"
  description = "OCI resources security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-oci"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "oci_sg_egress_1" {
  count             = var.enable_oci_db == "true" ? 1 : 0
  description       = "Allows app tier to access OCI resources"
  from_port         = var.oci_db_port
  protocol          = "tcp"
  security_group_id = aws_security_group.oci_resources[0].id
  to_port           = var.oci_db_port
  type              = "egress"
  cidr_blocks       = [var.vcn_cidr]
}

##
#  SNOWFLAKE
##
resource "aws_security_group" "snowflake" {
  count       = var.enable_snowflake == "true" ? 1 : 0
  name        = "${var.aws_region}-${var.customer}-${var.env}-snowflake_endpoint"
  description = "Snowflake endpoint security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-snowflake_endpoint"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "snowflake_ingress_1" {
  count             = var.enable_snowflake == "true" ? 1 : 0
  description       = "Allow general Snowflake traffic"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${var.internal_cidr_start1}.0/23"]
  security_group_id = aws_security_group.snowflake[0].id
}

resource "aws_security_group_rule" "snowflake_ingress_2" {
  count             = var.enable_snowflake == "true" ? 1 : 0
  description       = "Required for the Snowflake OCSP cache server, which listens for all Snowflake client communication on this port"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${var.internal_cidr_start1}.0/23"]
  security_group_id = aws_security_group.snowflake[0].id
}

# Spark MQ broker
resource "aws_security_group" "mq_broker" {
  count       = var.enable_spark == "true" ? 1 : 0
  name        = "${var.aws_region}-${var.customer}-${var.env}-mq_broker"
  description = "MQ broker security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-mq_broker"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "mq_broker_ingress_1" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "inbound CV to access RabbitMQ"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mq_broker[0].id
  to_port                  = var.mq_broker_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "mq_broker_ingress_2" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "inbound tomcat to access RabbitMQ"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mq_broker[0].id
  to_port                  = var.mq_broker_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "mq_broker_ingress_3" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "inbound execution cluster to access RabbitMQ"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mq_broker[0].id
  to_port                  = var.mq_broker_port
  type                     = "ingress"
  source_security_group_id = module.exe_emr_cluster.master_security_group_id
}

resource "aws_security_group_rule" "mq_broker_egress_3" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound RabbitMQ to cv"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mq_broker[0].id
  to_port                  = var.mq_broker_port
  type                     = "egress"
  source_security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "mq_broker_egress_4" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound RabbitMQ to tomcat"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mq_broker[0].id
  to_port                  = var.mq_broker_port
  type                     = "egress"
  source_security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "exe_master_egress_1" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound execution gateway to endpoint"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.exe_emr_cluster.master_security_group_id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

resource "aws_security_group_rule" "exe_master_egress_2" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound execution gateway to rabbitMQ"
  from_port                = var.mq_broker_port
  protocol                 = "tcp"
  security_group_id        = module.exe_emr_cluster.master_security_group_id
  to_port                  = var.mq_broker_port
  type                     = "egress"
  source_security_group_id = aws_security_group.mq_broker[0].id
}

resource "aws_security_group_rule" "exe_slave_egress_1" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound execution engine to endpoint"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.exe_emr_cluster.slave_security_group_id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

resource "aws_security_group_rule" "thrift_master_egress_1" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound thrift server to endpoint"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.thrift_emr_cluster.master_security_group_id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

resource "aws_security_group_rule" "thrift_slave_egress_1" {
  count                    = var.enable_spark == "true" ? 1 : 0
  description              = "outbound thrift worker to endpoint"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.thrift_emr_cluster.slave_security_group_id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

##
#  WebProxy
##
resource "aws_security_group" "webproxy" {
  count       = var.enable_webproxy == "true" ? 1 : 0
  name        = "${var.aws_region}-${var.customer}-${var.env}-webproxy_endpoint"
  description = "webproxy endpoint security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-webproxy_endpoint"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "webproxy_ingress_1" {
  count             = var.enable_webproxy == "true" ? 1 : 0
  description       = "Allow inbound to webproxy from CV"
  type              = "ingress"
  from_port         = var.webproxy_port
  to_port           = var.webproxy_port
  protocol          = "tcp"
  cidr_blocks       = ["${var.internal_cidr_start1}.0/23"]
  security_group_id = aws_security_group.webproxy[0].id
}
