# Try to get existing secret first
data "aws_secretsmanager_secret" "existing_secret" {
  name = "${var.environment}-app-secrets"
}

# Create new secret only if existing secret doesn't exist
resource "aws_secretsmanager_secret" "app_secrets" {
  count = try(data.aws_secretsmanager_secret.existing_secret.arn, null) == null ? 1 : 0

  name        = "${var.environment}-app-secrets"
  description = "Application secrets for environment: ${var.environment}"

  tags = {
    Name        = "${var.environment}-app-secrets"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  
  lifecycle {
    # Prevent destruction of secrets that might contain important data
    prevent_destroy = true
  }
}

# Local values to get the correct secret ARN and ID
locals {
  # Use existing secret if it exists, otherwise use created secret
  secret_arn = try(data.aws_secretsmanager_secret.existing_secret.arn, aws_secretsmanager_secret.app_secrets[0].arn)
  secret_id  = try(data.aws_secretsmanager_secret.existing_secret.id, aws_secretsmanager_secret.app_secrets[0].id)
}

# Optional secret version - only create if initial_secrets is provided
resource "aws_secretsmanager_secret_version" "app_secrets" {
  count = var.initial_secrets != null ? 1 : 0
  
  secret_id     = local.secret_id
  secret_string = jsonencode(var.initial_secrets)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
