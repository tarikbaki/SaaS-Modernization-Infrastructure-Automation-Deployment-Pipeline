############################################
# ElastiCache Redis (replication group)
############################################
resource "aws_elasticache_subnet_group" "redis" {
  count      = var.create_redis ? 1 : 0
  name       = "${var.name}-redis-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_security_group" "redis_sg" {
  count       = var.create_redis ? 1 : 0
  name        = "${var.name}-redis-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Redis 6379 from app_sg"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "Redis from app_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress"
  }

  tags = {
    Name = "${var.name}-redis-sg"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.create_redis ? 1 : 0

  replication_group_id       = "${var.name}-redis"
  description                = "App Redis"
  engine                     = "redis"
  engine_version             = var.redis_engine_ver
  node_type                  = var.redis_node_type
  automatic_failover_enabled = var.redis_replicas > 0
  num_node_groups            = 1
  replicas_per_node_group    = var.redis_replicas

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  security_group_ids = [aws_security_group.redis_sg[0].id]
  subnet_group_name  = aws_elasticache_subnet_group.redis[0].name
}
