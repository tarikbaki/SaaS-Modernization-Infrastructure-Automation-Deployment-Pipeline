data "aws_availability_zones" "az" { state = "available" }

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.vpc.id }

# Public subnets (2AZ)
resource "aws_subnet" "public" {
  count  = 2
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

# Private subnets (2AZ)
resource "aws_subnet" "private" {
  count  = 2
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.az.names[count.index]
  tags = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_eip" "nat" { vpc = true }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
}

# Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.igw.id }
}
resource "aws_route_table_association" "pub_assoc" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route { cidr_block = "0.0.0.0/0" nat_gateway_id = aws_nat_gateway.nat.id }
}
resource "aws_route_table_association" "priv_assoc" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name = "${var.name}-alb-sg"
  vpc_id = aws_vpc.vpc.id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "app_sg" {
  name = "${var.name}-app-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

# IAM for EC2 (SSM + ECR ReadOnly)
resource "aws_iam_role" "ec2_role" {
  name = "${var.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[{Effect="Allow", Action="sts:AssumeRole", Principal={Service="ec2.amazonaws.com"}}]
  })
}
resource "aws_iam_role_policy_attachment" "ssm"  { role=aws_iam_role.ec2_role.name policy_arn="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_role_policy_attachment" "ecr"  { role=aws_iam_role.ec2_role.name policy_arn="arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" }
resource "aws_iam_instance_profile" "profile"    { name="${var.name}-ec2-profile" role=aws_iam_role.ec2_role.name }

# ECR repo
resource "aws_ecr_repository" "repo" {
  name = "${var.name}-app"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
}

# EC2 (private subnets)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    yum update -y
    amazon-linux-extras enable docker
    yum install -y docker
    systemctl start docker && systemctl enable docker
    docker run -d --name app -p 80:80 public.ecr.aws/nginx/nginx:latest
  EOF
}

resource "aws_instance" "staging" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = local.user_data
  tags = { Name = "${var.name}-staging" }
}

resource "aws_instance" "prod" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[1].id
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = local.user_data
  tags = { Name = "${var.name}-production" }
}

# ALB + TGs + Listener
resource "aws_lb" "alb" {
  name = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "tg_prod" {
  name = "${var.name}-tg-prod"
  port=80 protocol="HTTP" vpc_id=aws_vpc.vpc.id
  health_check { path="/"; matcher="200-399"; interval=15; timeout=5; healthy_threshold=2; unhealthy_threshold=2 }
}

resource "aws_lb_target_group" "tg_stg" {
  name = "${var.name}-tg-stg"
  port=80 protocol="HTTP" vpc_id=aws_vpc.vpc.id
  health_check { path="/"; matcher="200-399"; interval=15; timeout=5; healthy_threshold=2; unhealthy_threshold=2 }
}

resource "aws_lb_target_group_attachment" "attach_prod" { target_group_arn=aws_lb_target_group.tg_prod.arn target_id=aws_instance.prod.id port=80 }
resource "aws_lb_target_group_attachment" "attach_stg"  { target_group_arn=aws_lb_target_group.tg_stg.arn  target_id=aws_instance.staging.id port=80 }

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port=80 protocol="HTTP"
  default_action { type="forward" target_group_arn=aws_lb_target_group.tg_prod.arn }
}

resource "aws_lb_listener_rule" "staging_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action { type="forward" target_group_arn=aws_lb_target_group.tg_stg.arn }
  condition { path_pattern { values=["/staging*", "/stg*"] } }
}

# SSM parameters for image tags (updated by pipeline )
resource "aws_ssm_parameter" "img_tag_prod" { name="/saas/${var.name}/imageTag/prod" type="String" value="latest" }
resource "aws_ssm_parameter" "img_tag_stg"  { name="/saas/${var.name}/imageTag/staging" type="String" value="latest" }
