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
    error_message = "Must be a valid CIDR notation."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for app servers"
  default     = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS (443)"
}
