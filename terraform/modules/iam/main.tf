# Try to use existing IAM role for ECS task execution, create if not exists
data "aws_iam_role" "ecs_task_execution_role_existing" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.ecs_task_execution_role_name}-${var.environment}"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.ecs_task_execution_role_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.ecs_task_execution_role_name}-${var.environment}"
  })
}

# Inline policy for ECS task execution role to access Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  count    = var.use_existing_roles ? 0 : 1
  name     = "ecs-task-execution-secrets-access"
  role     = aws_iam_role.ecs_task_execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arn
      }
    ]
  })
}

# Attach the ECS task execution role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  count      = var.use_existing_roles ? 0 : 1
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Try to use existing IAM role for ECS task, create if not exists
data "aws_iam_role" "ecs_task_role_existing" {
  count = var.use_existing_roles ? 1 : 0
  name  = "${var.ecs_task_role_name}-${var.environment}"
}

resource "aws_iam_role" "ecs_task_role" {
  count = var.use_existing_roles ? 0 : 1
  name  = "${var.ecs_task_role_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.ecs_task_role_name}-${var.environment}"
  })
}
