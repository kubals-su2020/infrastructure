provider "aws" {
  region = "${var.region}"
}
resource "aws_vpc" "assignment4_vpc" {

  cidr_block = "${var.vpc_cidr}"

  enable_dns_support = true
  enable_dns_hostnames = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = true
  instance_tenancy = "dedicated"

  tags = {
    Name = "assignment4_vpc"
  }
}

resource "aws_subnet" "assignment4_subnets" {

  count = "${length(var.subnet_cidr)}"
  availability_zone = "${element(data.aws_availability_zones.availability_zone_names.names,count.index)}"
  vpc_id     = "${aws_vpc.assignment4_vpc.id}"
  cidr_block = "${element(var.subnet_cidr,count.index)}"
  

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_a4_${count.index+1}"
  }
}

resource "aws_internet_gateway" "a4_gw" {
  vpc_id = "${aws_vpc.assignment4_vpc.id}"
  tags = {
      Name = "a4_gateway"
  }
}





resource "aws_route_table" "a4_route_table" {
  vpc_id = "${aws_vpc.assignment4_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.a4_gw.id}"
  }

  tags = {
    Name = "a4_route_table"
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(var.subnet_cidr)}"

  subnet_id      = "${element(aws_subnet.assignment4_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.a4_route_table.id}"
}