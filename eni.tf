resource "aws_network_interface" "bastion" {
  count           = var.ssh_access == "true" ? 1 : 0
  subnet_id       = aws_subnet.front_b.id
  security_groups = [aws_security_group.bastion.id]

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-bastion_eni"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

############################################################
# Elastic IPs
############################################################

resource "aws_eip" "nateip1a" {
  vpc = true
}

resource "aws_eip" "bastion" {
  count             = var.ssh_access == "true" ? 1 : 0
  vpc               = true
  network_interface = aws_network_interface.bastion[0].id
}

