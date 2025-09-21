output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = var.rds_security_group_id
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = var.db_secret_arn
}
