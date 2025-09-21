provider "aws" {
  region = var.region
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
  depends_on   = [module.vpc]
}

module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnet_ids
  rds_security_group_id = module.security_groups.rds_security_group_id
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_secret_arn         = module.secrets.secret_arn
  environment           = var.environment
  project_name          = var.project_name
  depends_on            = [module.vpc, module.secrets, module.security_groups]
}

module "alb" {
  source                = "./modules/alb"
  vpc_id                = module.vpc.vpc_id
  public_subnets        = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  environment           = var.environment
  project_name          = var.project_name
  depends_on            = [module.vpc, module.security_groups]
}

module "iam" {
  source                       = "./modules/iam"
  use_existing_roles           = var.use_existing_roles
  ecs_task_execution_role_name = var.ecs_task_execution_role_name
  ecs_task_role_name           = var.ecs_task_role_name
  environment                  = var.environment
  secrets_arn                  = module.secrets.secret_arn
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
  depends_on                   = [module.secrets]
}

module "secrets" {
  source      = "./modules/secrets"
  environment = var.environment
  initial_secrets = var.db_username != null && var.db_password != null ? {
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
  } : null
}

module "ecs" {
  source                        = "./modules/ecs"
  vpc_id                        = module.vpc.vpc_id
  public_subnets                = module.vpc.public_subnet_ids
  private_subnets               = module.vpc.private_subnet_ids
  ecs_security_group_id         = module.security_groups.ecs_security_group_id
  task_cpu                      = var.task_cpu
  task_memory                   = var.task_memory
  desired_count                 = var.desired_count
  min_capacity                  = var.min_capacity
  max_capacity                  = var.max_capacity
  container_image               = var.container_image
  db_endpoint                   = module.rds.rds_endpoint
  db_name                       = var.db_name
  db_secret_arn                 = module.secrets.secret_arn
  target_group_arn              = module.alb.target_group_arn
  environment                   = var.environment
  project_name                  = var.project_name
  log_group_name                = var.log_group_name
  ecs_task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.iam.ecs_task_role_arn
  depends_on                    = [module.vpc, module.rds, module.alb, module.iam, module.secrets, module.security_groups]
}

# Output the important information
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.rds_endpoint
}

output "db_secret_arn" {
  description = "ARN of the application secrets"
  value       = module.secrets.secret_arn
  sensitive   = true
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.ecs_task_role_arn
}
