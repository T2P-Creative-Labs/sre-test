# Development environment variables
environment = "dev"
project_name = "wordpress"

# VPC Configuration
region = "ap-northeast-1"
vpc_cidr = "10.0.0.0/16"
public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]

# ECS Configuration
task_cpu = "512"
task_memory = "1024"
desired_count = 1
min_capacity = 1
max_capacity = 2
container_image = "nginx:latest" # For testing, replace with your WordPress image

# Database Configuration
db_name = "wordpress"
db_instance_class = "db.t3.micro"

# Logs group name
log_group_name = "/ecs/wordpress-dev"

# IAM Configuration
ecs_task_execution_role_name = "wordpress-ecs-task-execution-role"
ecs_task_role_name = "wordpress-ecs-task-role"

# Secrets Management Configuration
db_username = "wordpress"
# Note: db_password should be set via environment variable or Terraform prompt
# Example: export TF_VAR_db_password="your-secure-password"
