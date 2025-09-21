# Subnet group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project = var.project_name
  }
}

# Get database credentials from the provided secret ARN
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_secret_arn
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

# RDS instance
resource "aws_db_instance" "main" {
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  username               = local.db_credentials.DB_USERNAME
  password               = local.db_credentials.DB_PASSWORD
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  multi_az               = true
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Project = var.project_name
  }
}
