module "vpc_1" {
    source = "../modules/networking"
    vpc_cidr = "10.0.0.0/16"
    tenancy = "default"
    subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    tag = "a4"
}

# module "vpc_2" {
#     source = "../modules/networking"
#     vpc_cidr = "10.0.0.0/16"
#     tenancy = "default"
#     subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
#     tag = "superman"
# }