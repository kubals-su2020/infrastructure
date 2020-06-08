provider "aws" {
  region = "${var.region}"
}
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = true
  instance_tenancy = "${var.tenancy}"

  tags = {
    Name = "vpc_${var.tag}"
  }
}
resource "aws_subnet" "main" {
  count = "${length(var.subnet_cidr)}"
  availability_zone = "${element(data.aws_availability_zones.availability_zone_names.names,count.index)}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${element(var.subnet_cidr,count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_${var.tag}_${count.index+1}"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
      Name = "internet_gateway_${var.tag}"
  }
}
resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "${var.public_route_cidr}"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "route_table_${var.tag}"
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(var.subnet_cidr)}"

  subnet_id      = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.main.id}"
}