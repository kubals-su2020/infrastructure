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
# assignment 5
# App security group
resource "aws_security_group" "application" {
  name        = "application"
  description = "ingress rules for port on which application runs"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "for ssh open port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "for http open port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "for https open port 442"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "for http-server open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "for angular application on build open port 4200"
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "application"
  }
}
# DB Security Group
resource "aws_security_group" "database" {
  name        = "database"
  description = "ingress rules for port on which database runs"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "for mysql open port 80"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.application.id}"]
  }
  tags = {
    Name = "database"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "aws_s3_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"
  force_destroy = true
  tags = {
    Name        = "${var.s3_bucket_name}"
    Environment = "Dev"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.mykey.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  lifecycle_rule {
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }
  }
}
# RDS instance

resource "aws_subnet" "rds" {
  count                   = "${length(var.subnet_cidr)}"
  # "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.${length(var.subnet_cidr) + count.index + 1}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${element(data.aws_availability_zones.availability_zone_names.names, count.index)}"
  tags = {
    Name = "rds-${element(data.aws_availability_zones.availability_zone_names.names, count.index)}"
  }
}
resource "aws_db_subnet_group" "default" {
  name        = "${var.aws_db_instance_identifier}-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = "${aws_subnet.rds.*.id}"
}
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "${var.aws_db_instance_name}"
  username             = "${var.aws_db_instance_username}"
  password             = "${var.aws_db_instance_password}"
  parameter_group_name = "default.mysql5.7"
  multi_az = false
  identifier =  "${var.aws_db_instance_identifier}"
  publicly_accessible = false
  skip_final_snapshot       = true
  vpc_security_group_ids    = ["${aws_security_group.database.id}"]
   db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"

  count = "${length(var.subnet_cidr)}"
  subnet_id = "${element(aws_subnet.main.*.id, count.index)}"
  associate_public_ip_address = true


  root_block_device{
    volume_size = 20
    volume_type ="gp2"
    delete_on_termination = true
  }
  # ebs_block_device{
  #   device_name = "${aws_db_instance.default.name}"
  #   delete_on_termination = true
  # }
  vpc_security_group_ids = ["${aws_security_group.application.id}"]
  # security_groups = [ "${aws_security_group.application.name}" ]
  depends_on = ["aws_db_instance.default"]
  iam_instance_profile = "${aws_iam_instance_profile.IAM_profile.id}"



  tags = {
    Name = "ec2 instance"
  }
}

# DynamoDB Table
# resource "aws_dynamodb_table" "csye6225" {
#   name             = "${var.dynamodb_table_name}"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "UserId"
#   range_key      = "GameTitle"

#   attribute {
#     name = "id"
#     type = "S"
#   }
#   tags = {
#     Name        = "${var.aws_db_instance_name}"
#     Environment = "dev"
#   }
# }


#IAM role
resource "aws_iam_role" "EC2-CSYE6225" {
  name = "${var.IAM_role_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}


resource "aws_iam_instance_profile" "IAM_profile" {
  name = "IAM_profile"
  role = "${aws_iam_role.EC2-CSYE6225.name}"
}
resource "aws_iam_policy" "WebAppS3" {
  name        = "WebAppS3"
  path        = "/"
  description = "My teWebAppS3st policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::aws_s3_bucket",
        "arn:aws:s3:::aws_s3_bucket/*"]
    }
  ]
}
EOF
}