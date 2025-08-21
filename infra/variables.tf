variable "name" {
  type        = string
  default     = "saas-modernization-infra--prod"
  description = "Name prefix; keep short (ALB/TG 32-char limit)."
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type        = string
  default     = "ami-08c40ec9ead489470"
  description = "Optional explicit AMI id; if empty, AL2 latest will be used."
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN used by ALB HTTPS (443)"
}

# --- toggles & sizes for DB/Cache ---
variable "create_aurora" {
  type    = bool
  default = true
}

variable "create_redis" {
  type    = bool
  default = true
}

variable "db_engine" {
  type    = string
  default = "aurora-mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0.mysql_aurora.3.04.1"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "redis_engine_ver" {
  type    = string
  default = "7.0"
}

variable "redis_replicas" {
  type    = number
  default = 1
}
