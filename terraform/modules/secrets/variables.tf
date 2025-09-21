variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "initial_secrets" {
  description = "Initial secrets to store (optional). Can be managed externally using manage-secrets.sh script."
  type        = map(string)
  default     = null
  sensitive   = true
}

