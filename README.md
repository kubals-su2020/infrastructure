# infrastructure
This repository contains terraform files to setup the infrastructure

Go to dev folder to create VPC and subnets for dev
and run following commands in dev


set keys in the terminal using 

$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"

Do following to plan the configuration and validate
1. terraform plan 

Do following to apply changes to aws and add new vpc
2.  terraform apply