############################################
# Security Groups
############################################

# ALB Security Group – public 80 (redirect) + 443 (HTTPS)
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG: allow 80/443 from internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP for redirect to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS public entry"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# App Security Group – only from ALB SG (80 + 443 for future TLS to instances)
resource "aws_security_group" "app_sg" {
  name        = "${var.name}-app-sg"
  description = "App SG: allow HTTP/HTTPS only from ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-app-sg"
  }
}
