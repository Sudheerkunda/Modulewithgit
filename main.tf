#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.vpc_name}"
    }
    # depends_on = [ aws_s3_bucket.b]
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
	tags = {
        Name = "${var.IGW_name}"
    }
}

resource "aws_subnet" "subnets" {
    count = 2 #0,1
    vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${element(var.cidr, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"
    tags = {
        Name = "Dev-subnet-${count.index+1}"
    }

}

# resource "aws_subnet" "subnet2-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet2_cidr}"
#     availability_zone = "us-east-1b"

#     tags = {
#         Name = "${var.public_subnet2_name}"
#     }
# }

# resource "aws_subnet" "subnet3-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet3_cidr}"
#     availability_zone = "us-east-1c"

#     tags = {
#         Name = "${var.public_subnet3_name}"
#     }
	
# }

resource "aws_route_table" "terraform-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "${var.Main_Routing_Table}"
    }
}

resource "aws_route_table_association" "terraform-public" {
    count = 2
    subnet_id = "${element(aws_subnet.subnets.*.id, count.index)}"
    # subnet_id = "${aws_subnet.subnet1-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"
}
#   resource "aws_s3_bucket" "b" {
#   bucket = "sudheer-kunda-depends-on"
#   acl    = "private"

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
# }

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     cidr_blocks     = ["0.0.0.0/0"]
#     }
# }

# data "aws_ami" "my_ami" {
#      most_recent      = true
#      #name_regex       = "^mavrick"
#      owners           = ["721834156908"]
# }


resource "aws_instance" "web-1" {
    count = "${var.environment == "dev" ? 2 : 1 }"
    ami = "${lookup(var.amis, var.aws_region)}"
    #ami = "ami-0d857ff0f5fc4e03b"
    # availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "JANUARY-2020-KEY"
    subnet_id = "${element(aws_subnet.subnets.*.id, count.index)}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true	
    tags = {
        Name = "Server-dev-${count.index+1}"
        Env = "dev"
        Owner = "sudheer"
    }
}

#output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}"
#}
#!/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var 'aws_access_key=AAAAAAAAAAAAAAAAAA' -var 'aws_secret_key=BBBBBBBBBBBBB' packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve
