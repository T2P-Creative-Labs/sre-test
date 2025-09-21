# Production environment variables
environment = "prod"
project_name = "wordpress"

# VPC Configuration
region = "ap-northeast-1"
vpc_cidr = "10.1.0.0/16"
public_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets = ["10.1.3.0/24", "10.1.4.0/24"]
availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]

# ECS Configuration
task_cpu = "1024"
task_memory = "2048"
desired_count = 3
min_capacity = 2
max_capacity = 10
container_image = "wordpress:latest"

# Database Configuration
db_name = "wordpress"
db_instance_class = "db.t3.small"

# Logs group name
log_group_name = "/ecs/wordpress"

# IAM Configuration
ecs_task_execution_role_name = "wordpress-ecs-task-execution-role"
ecs_task_role_name = "wordpress-ecs-task-role"

# Secrets Management Configuration
db_username = "wordpress"
# Note: db_password should be set via environment variable or Terraform prompt
# Example: export TF_VAR_db_password="your-secure-password"
