output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "ecr_repo_url" {
  description = "ECR repository URL for the app"
  value       = aws_ecr_repository.repo.repository_url
}

output "aurora_reader_endpoint" {
  value       = try(aws_rds_cluster.aurora[0].reader_endpoint, null)
  description = "Aurora reader endpoint"
}

output "aurora_writer_endpoint" {
  value       = try(aws_rds_cluster.aurora[0].endpoint, null)
  description = "Aurora writer endpoint"
}

output "db_secret_arn" {
  value       = try(aws_secretsmanager_secret.db[0].arn, null)
  description = "Secrets Manager ARN for DB credentials"
}

output "redis_primary_endpoint" {
  value       = try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null)
  description = "Redis primary endpoint"
}
