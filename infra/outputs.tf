output "staging_instance_ip" {
  value = aws_instance.staging.public_ip
}

output "production_instance_ip" {
  value = aws_instance.production.public_ip
}

output "load_balancer_dns" {
  value = aws_elb.app_lb.dns_name
}