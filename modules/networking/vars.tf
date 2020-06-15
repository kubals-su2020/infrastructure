variable "region" {
  type = "string"
  default = "us-east-1"
}
variable "vpc_cidr" {
  type = "string"
  default = "10.0.0.0/16"
}
variable "tenancy" {
  type = "string"
  default = "default"
}
variable "subnet_cidr" {
  type = "list"
  default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
} 
# variable "availability_zone_names" {
#   type = list(string)
#   list = ["us-east-1a","us-east-1b","us-east-1c"]
# }
# Declare the data source
variable "public_route_cidr" {
  type = "string"
  default = "0.0.0.0/0"
}

variable "tag" {
  type = "string"
  default = "assignment-4"
}
data "aws_availability_zones" "availability_zone_names" {
}


resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
variable "ami" {
  type = "string"
  default = "ami-059756b9cfd567f32"
}

variable "s3_bucket_name" {
  type = "string"
  default = "webapp.shalvi.kubal"
}

variable "aws_db_instance_username" {
  type = "string"
  default = "csye6225su2020"
}

variable "aws_db_instance_password" {
  type = "string"
  default = "Varad123"
}
variable "aws_db_instance_name" {
  type = "string"
  default = "csye6225"
}
variable "aws_db_instance_identifier" {
  type = "string"
  default = "csye6225-su2020"
}
variable "dynamodb_table_name" {
  type = "string"
  default = "csye6225"
}

variable "IAM_role_name" {
  type = "string"
  default = "EC2-CSYE6225"
  
}
