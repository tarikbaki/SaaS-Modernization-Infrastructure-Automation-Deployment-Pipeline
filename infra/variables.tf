variable "name" {
  type        = string
  description = "Base name prefix for resources"
  default     = "saas"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for app servers"
  default     = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "AMI ID override; leave empty to use latest Amazon Linux 2"
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS (443). Must be in the same region."
}
