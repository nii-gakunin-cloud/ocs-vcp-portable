# Usage:
#
# docker run -ti -v "$(pwd):/app" -w /app hashicorp/terraform init
# docker run -ti -v "$(pwd):/app" -w /app \
#   -e AWS_ACCESS_KEY_ID="anaccesskey" \
#   -e AWS_SECRET_ACCESS_KEY="asecretkey" \
#   -e AWS_DEFAULT_REGION="ap-northeast-1" \
#   hashicorp/terraform apply
#
# var.local_subnet
#   Enter a value: 
# var.my_public_ip
#   Enter a value: 

variable "local_subnet" {}
variable "my_public_ip" {}

variable "vpc_name"          { default = "ocs-portable" }
variable "vpc_cidr_block"    { default = "172.30.0.0/16" }
variable "public_subnet"     { default = "172.30.1.0/24" }
variable "private_subnet"    { default = "172.30.2.0/24" }
variable "availability_zone" { default = "" }

provider "aws" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "subnet-pub" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-pub"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet-priv" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone == "" ? data.aws_availability_zones.available.names[0] : var.availability_zone
  tags = {
    Name = "${var.vpc_name}-priv"
  }
}

resource "aws_security_group" "sg-main" {
  name   = "${var.vpc_name}-main"
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = "-1"
    self      = "true"
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [var.local_subnet]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-main"
  }
}

resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-pub"
  }
}

resource "aws_route_table_association" "rta-pub" {
  route_table_id = aws_route_table.rt-pub.id
  subnet_id      = aws_subnet.subnet-pub.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_route" "r-pub" {
  route_table_id         = aws_route_table.rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table" "rt-priv" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-priv"
  }
}

resource "aws_main_route_table_association" "mrta-priv" {
  vpc_id = aws_vpc.vpc.id
  route_table_id = aws_route_table.rt-priv.id
}

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.vpc_name}-natgw"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet-pub.id
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_route" "r-priv" {
  route_table_id         = aws_route_table.rt-priv.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn    = 65000
  type       = "ipsec.1"
  ip_address = var.my_public_ip
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_vpn_connection" "vpn_conn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_vpn_connection_route" "vpn_route" {
  vpn_connection_id      = aws_vpn_connection.vpn_conn.id
  destination_cidr_block = var.local_subnet
}

resource "aws_route" "r-priv2" {
  route_table_id         = aws_route_table.rt-priv.id
  gateway_id             = aws_vpn_gateway.vgw.id
  destination_cidr_block = var.local_subnet
}

###################################

output "aws_vpc_subnet_id" {
  value = aws_subnet.subnet-priv.id
}

output "aws_vpc_security_group_id" {
  value = aws_security_group.sg-main.id
}

output "aws_availability_zone" {
  value = aws_subnet.subnet-priv.availability_zone
}

output "private_network_ipmask" {
  value = aws_subnet.subnet-priv.cidr_block
}
