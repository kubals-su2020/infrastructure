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
    security_groups = ["${aws_security_group.lb.id}"]
  }

  ingress {
    description = "for http open port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }
  ingress {
    description = "for https open port 442"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }
  ingress {
    description = "for http-server open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }
  ingress {
    description = "for angular application on build open port 4200"
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }
  ingress {
    description = "for angular application on build open port 4200"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "for http-server open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "open port 3000"
    from_port   = 3000
    to_port     = 3000
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
    security_groups = ["${aws_security_group.application.id}"]
  }
  tags = {
    Name = "database"
  }
}

resource "aws_security_group" "lb" {
  name        = "load-balancer"
  description = "rules for load balancer"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "open port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "open port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "open port 8080"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "open port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer"
  }
}

# S3 Bucket
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
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
        sse_algorithm = "AES256"
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

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = "${aws_s3_bucket.aws_s3_bucket.id}"

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# RDS instance

# resource "aws_subnet" "rds" {
#   count                   = "${length(var.subnet_cidr)}"
#   # "${length(data.aws_availability_zones.available.names)}"
#   vpc_id                  = "${aws_vpc.main.id}"
#   cidr_block              = "10.0.${length(var.subnet_cidr) + count.index + 1}.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "${element(data.aws_availability_zones.availability_zone_names.names, count.index)}"
#   tags = {
#     Name = "rds-${element(data.aws_availability_zones.availability_zone_names.names, count.index)}"
#   }
# }
# resource "aws_db_subnet_group" "default" {
#   name        = "${var.aws_db_instance_identifier}-subnet-group"
#   description = "Terraform example RDS subnet group"
#   subnet_ids  = "${aws_subnet.rds.*.id}"
# }

resource "aws_db_subnet_group" "default" {
  name        = "${var.aws_db_instance_identifier}-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = "${aws_subnet.main.*.id}"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.medium"
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
# resource "aws_instance" "web" {
#   ami           = "${var.ami}"
#   instance_type = "t2.micro"

#   subnet_id = "${element(aws_subnet.main.*.id, 0)}"
#   associate_public_ip_address = true


#   root_block_device {
#     volume_size = 20
#     volume_type = "gp2"
#     delete_on_termination = true
#   }

#   user_data = <<-EOF
#                 #! /bin/bash
#                 touch /opt/config.properties
#                 echo db_username="${var.aws_db_instance_username}" >> /opt/config.properties
#                 echo db_password="${var.aws_db_instance_password}" >> /opt/config.properties
#                 echo db_hostname="${aws_db_instance.default.address}" >> /opt/config.properties
#                 echo db_database="${aws_db_instance.default.name}" >> /opt/config.properties
#                 echo s3_bucket_name="${aws_s3_bucket.aws_s3_bucket.id}" >> /opt/config.properties                              
#   EOF

#   vpc_security_group_ids = ["${aws_security_group.application.id}"]
#   # security_groups = [ "${aws_security_group.application.name}" ]
#   depends_on = ["aws_db_instance.default"]
#   iam_instance_profile = "${aws_iam_instance_profile.IAM_profile.id}"

#   key_name = "${aws_key_pair.public_key.key_name}"

#   tags = {
#     Name = "ec2 instance"
#     CodeDeploy = "true"
#   }
# }

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
# DynamoDB Table
resource "aws_dynamodb_table" "main" {
  name           = "${var.dynamodb_table_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name  = "dynamodb-table"
  }
}

#IAM role
# resource "aws_iam_role" "EC2-CSYE6225" {
#   name = "${var.IAM_role_name}"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF

#   tags = {
#     tag-key = "tag-value"
#   }
# }


# resource "aws_iam_policy" "WebAppS3" {
#   name        = "WebAppS3"
#   path        = "/"
#   description = "My WebAppS3 policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "s3:*"
#       ],
#       "Effect": "Allow",
#       "Resource": [
#         "arn:aws:s3:::${aws_s3_bucket.aws_s3_bucket.id}",
#         "arn:aws:s3:::${aws_s3_bucket.aws_s3_bucket.id}/*"]
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "test-attach" {
#   role       = "${aws_iam_role.EC2-CSYE6225.name}"
#   policy_arn = "${aws_iam_policy.WebAppS3.arn}"
# }

# profile to attach to EC2 having role CodeDeployEC2ServiceRole
resource "aws_iam_instance_profile" "IAM_profile" {
  name = "IAM_profile"
  role = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
}
# keypair for ec2 instance
resource "aws_key_pair" "public_key" {
  key_name   = "public-key"
  public_key = "${var.public_key}"
}

# policy for ec2 to access s3
resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"
  path        = "/"
  description = "CodeDeploy-EC2-S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.aws_s3_bucket.id}",
        "arn:aws:s3:::${aws_s3_bucket.aws_s3_bucket.id}/*",
        "arn:aws:s3:::codedeploy.shalvikubal.me",
        "arn:aws:s3:::codedeploy.shalvikubal.me/*"]
    }
  ]
} 
EOF
}

# policy for circleci user to upload application to s3
resource "aws_iam_policy" "CircleCI-Upload-To-S3" {
  name        = "CircleCI-Upload-To-S3"
  path        = "/"
  description = "CircleCI-Upload-To-S3"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.shalvikubal.me",
                "arn:aws:s3:::codedeploy.shalvikubal.me/*"]
        }
    ]
}
EOF
}
# policy for circleci user to run codedeploy
resource "aws_iam_policy" "CircleCI-Code-Deploy" {
  name        = "CircleCI-Code-Deploy"
  path        = "/"
  description = "CircleCI-Code-Deploy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:application:csye6225-webapp"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

# policy for circleci user to create ami
resource "aws_iam_policy" "CircleCI-ec2-ami" {
  name        = "CircleCI-ec2-ami"
  path        = "/"
  description = "CircleCI-ec2-ami"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
# attach policy to circleciuser(policy for circleci user to create ami)
resource "aws_iam_policy_attachment" "CircleCI_ec2_ami_policy_attachment" {
  name       = "CircleCI-ec2-ami-policy-attachment"
  users      = ["cicd"]
  policy_arn = "${aws_iam_policy.CircleCI-ec2-ami.arn}"
}
# attach policy to circleciuser(policy for circleci user to upload application to s3)
resource "aws_iam_policy_attachment" "CircleCI_Upload_To_S3_policy_attachment" {
  name       = "CircleCI-Upload-To-S3-policy-attachment"
  users      = ["cicd"]
  policy_arn = "${aws_iam_policy.CircleCI-Upload-To-S3.arn}"
}
# attach policy to circleciuser(policy for circleci user to run codedeploy)
resource "aws_iam_policy_attachment" "CircleCI_Code_Deploy_policy_attachment" {
  name       = "CircleCI-Code-Deploy-policy-attachment"
  users      = ["cicd"]
  policy_arn = "${aws_iam_policy.CircleCI-Code-Deploy.arn}"
}
# create role for EC2 instance profile 
resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = "CodeDeployEC2ServiceRole"

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

}

# resource "aws_iam_role" "EC2-CSYE6225" {
#   name = "${var.IAM_role_name}"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF

#   tags = {
#     tag-key = "tag-value"
#   }
# }
# attach (policy for ec2 to access s3) to role(CodeDeployEC2ServiceRole - role attached to ec2 profile)
resource "aws_iam_role_policy_attachment" "CodeDeployEC2ServiceAttach" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "${aws_iam_policy.CodeDeploy-EC2-S3.arn}"
}
# attach (attach cloud policy) to role(CodeDeployEC2ServiceRole - role attached to ec2 profile)
resource "aws_iam_role_policy_attachment" "CloudWatchEC2ServiceAttach" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
# attach (sns ploicy) to role(CodeDeployEC2ServiceRole - role attached to ec2 profile)
resource "aws_iam_role_policy_attachment" "SNSEC2ServiceAttach" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}
# role for code deploy service 
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# policy attachment to code deploy role
resource "aws_iam_role_policy_attachment" "CodeDeployServiceRoleAttach" {
  role       = "${aws_iam_role.CodeDeployServiceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
# code deploy application service created
resource "aws_codedeploy_app" "csye6225-webapp" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}
# code deploy group forcode deploy application service created
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = "${aws_codedeploy_app.csye6225-webapp.name}"
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn      = "${aws_iam_role.CodeDeployServiceRole.arn}"
  autoscaling_groups    = ["${aws_autoscaling_group.asg.name}"]

  ec2_tag_set {
    ec2_tag_filter {
      key   = "CodeDeploy"
      type  = "KEY_AND_VALUE"
      value = "true"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

resource "aws_codedeploy_deployment_group" "csye6225-webapp-backend-deployment" {
  app_name              = "${aws_codedeploy_app.csye6225-webapp.name}"
  deployment_group_name = "csye6225-webapp-backend-deployment"
  service_role_arn      = "${aws_iam_role.CodeDeployServiceRole.arn}"
  autoscaling_groups    = ["${aws_autoscaling_group.asg.name}"]

  ec2_tag_set {
    ec2_tag_filter {
      key   = "CodeDeploy"
      type  = "KEY_AND_VALUE"
      value = "true"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

#  assignment 8
# autoscaling launch configuration
resource "aws_launch_configuration" "asg_launch_config" {
  name          = "asg_launch_config"
  image_id      = "${var.ami}"
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.application.id}"]
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data = <<-EOF
                #! /bin/bash
                touch /opt/config.properties
                echo db_username="${var.aws_db_instance_username}" >> /opt/config.properties
                echo db_password="${var.aws_db_instance_password}" >> /opt/config.properties
                echo db_hostname="${aws_db_instance.default.address}" >> /opt/config.properties
                echo db_database="${aws_db_instance.default.name}" >> /opt/config.properties
                echo s3_bucket_name="${aws_s3_bucket.aws_s3_bucket.id}" >> /opt/config.properties  
                echo domain_name="${var.domain_name}" >> /opt/config.properties         
                echo target_arn = "${aws_sns_topic.password_reset.arn}" >> /opt/config.properties               
  EOF
  depends_on = ["aws_db_instance.default"]
  iam_instance_profile = "${aws_iam_instance_profile.IAM_profile.id}"
}

# autoscaling group
resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  launch_configuration = "${aws_launch_configuration.asg_launch_config.name}"
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  default_cooldown = 60
  vpc_zone_identifier = "${aws_subnet.main.*.id}"

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "CodeDeploy"
    value               = true
    propagate_at_launch = true
  }
}
# aws autoscaling policy - scale up
resource "aws_autoscaling_policy" "ScaleUpPolicy" {
  name                   = "ScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}
# aws autoscaling policy - scale down
resource "aws_autoscaling_policy" "ScaleDownPolicy" {
  name                   = "ScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}
# CPU utilization very high alarm - cloud watch
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "CPUAlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

  alarm_description = "Scale-up if CPU > 5% for 2 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.ScaleUpPolicy.arn}"]
}
# CPU utilization very low alarm - cloud watch
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = "CPUAlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "3"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

  alarm_description = "Scale-down if CPU < 3% for 2 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.ScaleDownPolicy.arn}"]
}
# setting up application load balancer
resource "aws_lb" "ApplicationLoadBalancer" {
  name               = "ApplicationLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb.id}"]
  subnets            = "${aws_subnet.main.*.id}"

  enable_deletion_protection = false
}
# ALB listener
resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = "${aws_lb.ApplicationLoadBalancer.arn}"  
  port              = "80"  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = "${aws_lb_target_group.webapp_target.arn}"
    type             = "forward"  
  }
}

resource "aws_alb_listener" "alb_listener_backend" {  
  load_balancer_arn = "${aws_lb.ApplicationLoadBalancer.arn}"  
  port              = "3000"  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = "${aws_lb_target_group.webapp_target_backend.arn}"
    type             = "forward"  
  }
}

# target group
resource "aws_lb_target_group" "webapp_target" {
  name     = "webapp-target"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  
  health_check {
    timeout = 30
    interval = 60
  }
}

resource "aws_lb_target_group" "webapp_target_backend" {
  name     = "webapp-target-backend"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  
  health_check {
    timeout = 30
    interval = 60
    path = "/test"
  }
}

# aws route 53
resource "aws_route53_record" "www" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.ApplicationLoadBalancer.dns_name}"
    zone_id                = "${aws_lb.ApplicationLoadBalancer.zone_id}"
    evaluate_target_health = true
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.webapp_target.arn}"
}

resource "aws_autoscaling_attachment" "asg_attachment_bar_backend" {
  autoscaling_group_name = "${aws_autoscaling_group.asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.webapp_target_backend.arn}"
}


#assignment 9
# create sns topic
resource "aws_sns_topic" "password_reset" {
  name = "password_reset"
}
#attach policy to sns topic
resource "aws_sns_topic_policy" "default" {
  arn = "${aws_sns_topic.password_reset.arn}"
  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}
# policy of sns for of who can access(account id) and operations it can perform
data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "${var.aws_account_id}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sns_topic.password_reset.arn}",
    ]

    sid = "__default_statement_ID"
  }
}
#create lambda function resource 
resource "aws_lambda_function" "func" {
  filename      = "exports.js.zip"
  function_name = "lambda_called_from_sns"
  role          = "${aws_iam_role.default.arn}"
  handler       = "exports.handler"
  runtime       = "nodejs10.x"
  depends_on = ["aws_iam_role_policy_attachment.lambda_logs"]
}
# log group for lambda
# This is to optionally manage the CloudWatch Log Group for the Lambda Function., "aws_cloudwatch_log_group.example"
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
# resource "aws_cloudwatch_log_group" "example" {
#   name              = "/aws/lambda/reset_password"
#   retention_in_days = 14
# }

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
# attach logging policy to lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.default.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}
# iam role for lambda
resource "aws_iam_role" "default" {
  name = "iam_for_lambda_with_sns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
# allow lambda execution from sns
resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.password_reset.arn}"
}
# subscribe lambda to sns
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${aws_sns_topic.password_reset.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.func.arn}"
}

# resource "aws_iam_role_policy_attachment" "ec2_SNS" {
# 	role = "${aws_iam_role.CodeDeployEC2ServiceAttach.name}"
# 	policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
# }

# ################# fake test load balancer jutsu ######################

# # setting up application load balancer
# resource "aws_lb" "TestLoadBalancer" {
#   name               = "TestLoadBalancer"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = ["${aws_security_group.test_lb.id}"]
#   subnets            = "${aws_subnet.main.*.id}"

#   enable_deletion_protection = false
# }
# # ALB listener
# resource "aws_alb_listener" "test_listener" {  
#   load_balancer_arn = "${aws_lb.TestLoadBalancer.arn}"  
#   port              = "80"  
#   protocol          = "HTTP"
  
#   default_action {    
#     target_group_arn = "${aws_lb_target_group.test_target.arn}"
#     type             = "forward"  
#   }
# }
# # target group
# resource "aws_lb_target_group" "test_target" {
#   name     = "test-target"
#   port     = 3000
#   protocol = "HTTP"
#   vpc_id   = "${aws_vpc.main.id}"
  
#   health_check {
#     timeout = 60
#     interval = 120
#   }
# }

# # aws route 53
# resource "aws_route53_record" "test" {
#   zone_id = "${var.hosted_zone_id}"
#   name    = "test.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = "${aws_lb.TestLoadBalancer.dns_name}"
#     zone_id                = "${aws_lb.TestLoadBalancer.zone_id}"
#     evaluate_target_health = true
#   }
# }

# # Create a new ALB Target Group attachment
# resource "aws_autoscaling_attachment" "test_attachment_bar" {
#   autoscaling_group_name = "${aws_autoscaling_group.asg.id}"
#   alb_target_group_arn   = "${aws_lb_target_group.test_target.arn}"
# }

# resource "aws_security_group" "test_lb" {
#   name        = "test-load-balancer"
#   description = "rules for load balancer"
#   vpc_id      = "${aws_vpc.main.id}"

#   ingress {
#     description = "open port 3000"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "open port 80"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "open port 3000"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "open port 80"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "test-load-balancer"
#   }
# }