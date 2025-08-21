############################################
# Aurora MySQL (1 writer + 1 reader)
############################################
resource "aws_db_subnet_group" "aurora" {
  count      = var.create_aurora ? 1 : 0
  name       = "${var.name}-aurora-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

# DB SG: only from app_sg on 3306
resource "aws_security_group" "db_sg" {
  count       = var.create_aurora ? 1 : 0
  name        = "${var.name}-db-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Aurora 3306 from app_sg"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "MySQL from app_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress"
  }

  tags = {
    Name = "${var.name}-db-sg"
  }
}

resource "random_password" "db_pwd" {
  count   = var.create_aurora ? 1 : 0
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  count = var.create_aurora ? 1 : 0
  name  = "${var.name}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  count     = var.create_aurora ? 1 : 0
  secret_id = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    username = "appuser"
    password = random_password.db_pwd[0].result
  })
}

resource "aws_rds_cluster" "aurora" {
  count                   = var.create_aurora ? 1 : 0
  cluster_identifier      = "${var.name}-aurora"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  database_name           = var.db_name
  master_username         = "appuser"
  master_password         = random_password.db_pwd[0].result
  db_subnet_group_name    = aws_db_subnet_group.aurora[0].name
  vpc_security_group_ids  = [aws_security_group.db_sg[0].id]
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
}

resource "aws_rds_cluster_instance" "aurora_writer" {
  count              = var.create_aurora ? 1 : 0
  identifier         = "${var.name}-aurora-w"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
}

resource "aws_rds_cluster_instance" "aurora_reader" {
  count              = var.create_aurora ? 1 : 0
  identifier         = "${var.name}-aurora-r"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
}
