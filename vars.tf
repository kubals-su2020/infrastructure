variable "region" {
  type = "string"
}

variable "vpc_cidr" {
  type = "string"
  default = "10.0.0.0/16"
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
data "aws_availability_zones" "availability_zone_names" {
}