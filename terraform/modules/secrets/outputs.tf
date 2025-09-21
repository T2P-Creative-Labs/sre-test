output "secret_arn" {
  description = "ARN of the application secrets"
  value       = local.secret_arn
}

output "secret_name" {
  description = "Name of the application secrets (follows pattern: {environment}-app-secrets)"
  value       = "${var.environment}-app-secrets"
}

output "secret_id" {
  description = "ID of the application secrets"
  value       = local.secret_id
}

