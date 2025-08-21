output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "ecr_repo_url" {
  description = "ECR repository URL for the app"
  value       = aws_ecr_repository.repo.repository_url
}
