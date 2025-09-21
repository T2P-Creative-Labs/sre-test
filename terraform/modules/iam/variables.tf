variable "use_existing_roles" {
  description = "Whether to use existing IAM roles or create new ones"
  type        = bool
  default     = false
}

variable "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  type        = string
  default     = "wordpress-ecs-task-execution-role"
}

variable "secrets_arn" {
  description = "ARN of the Secrets Manager secret for ECS tasks"
  type        = string
}

variable "ecs_task_role_name" {
  description = "Name of the ECS task role"
  type        = string
  default     = "wordpress-ecs-task-role"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
