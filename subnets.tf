# Public subnets for bastion, sftp instance
resource "aws_subnet" "front_a" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start1}.0/27"
  map_public_ip_on_launch = true

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-front_a"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "front_b" {
  availability_zone       = data.aws_availability_zones.available.names[1]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start1}.32/27"
  map_public_ip_on_launch = true

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-front_b"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "front_gateway_a" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start1}.64/27"
  map_public_ip_on_launch = true

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-front_gateway_a"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "front_gateway_b" {
  availability_zone       = data.aws_availability_zones.available.names[1]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start1}.96/27"
  map_public_ip_on_launch = true

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-front_gateway_b"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "app_a" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start2}.64/26"
  map_public_ip_on_launch = false

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-app_a"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "app_b" {
  availability_zone       = data.aws_availability_zones.available.names[1]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start2}.128/26"
  map_public_ip_on_launch = false

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-app_b"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "data_a" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start2}.0/27"
  map_public_ip_on_launch = false

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-data_a"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "data_b" {
  availability_zone       = data.aws_availability_zones.available.names[1]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start2}.32/27"
  map_public_ip_on_launch = false

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-data_b"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_subnet" "data_c" {
  count                   = var.use_2az == "1" ? 0 : 1
  availability_zone       = data.aws_availability_zones.available.names[length(data.aws_availability_zones.available.names) - 1]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.internal_cidr_start2}.224/27"
  map_public_ip_on_launch = false

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-data_c"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

