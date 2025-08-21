variable "name"        { type = string, default = "saas" }
variable "aws_region"  { type = string, default = "us-east-1" }
variable "vpc_cidr"    { type = string, default = "10.0.0.0/16" }
variable "instance_type" { type = string, default = "t3.micro" }
variable "ami_id"      { type = string, default = "ami-08c40ec9ead489470" } # Amazon Linux 2
