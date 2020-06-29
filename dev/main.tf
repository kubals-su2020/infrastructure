variable "ami" {}
variable "aws_account_id" {}
module "infrastructure" {
    source = "../modules/networking"
    vpc_cidr = "10.0.0.0/16"
    tenancy = "default"
    subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    tag = "a4"
    ami = "${var.ami}"
    aws_account_id = "${var.aws_account_id}"
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