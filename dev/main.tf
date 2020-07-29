variable "ami" {}
variable "aws_account_id" {}
variable "hosted_zone_id" {}
variable "domain_name" {}
variable "aws_acm_certificate_arn" {}
module "infrastructure" {
    source = "../modules/networking"
    vpc_cidr = "10.0.0.0/16"
    tenancy = "default"
    subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    tag = "a4"
    ami = "${var.ami}"
    aws_account_id = "${var.aws_account_id}"
    hosted_zone_id = "${var.hosted_zone_id}"
    domain_name = "${var.domain_name}"
    aws_acm_certificate_arn = "${var.aws_acm_certificate_arn}"

    # create_database_subnet_group = true
    # database_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] 
}

# module "vpc_2" {
#     source = "../modules/networking"
#     vpc_cidr = "10.0.0.0/16"
#     tenancy = "default"
#     subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
#     tag = "superman"
# }