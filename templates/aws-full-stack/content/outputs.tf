output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "app_url" {
  value = "https://${var.subdomain}.${var.domain}"
}

output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "s3_bucket" {
  value = aws_s3_bucket.this.id
}

output "asg_name" {
  value = aws_autoscaling_group.this.name
}
