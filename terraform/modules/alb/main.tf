# Target group for WordPress ECS service
resource "aws_lb_target_group" "wordpress_tg" {
  name        = "${var.project_name}-${var.environment}-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-tg"
    Environment = var.environment
    Project = var.project_name
  }
}

# ALB
resource "aws_lb" "wordpress_alb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project = var.project_name
  }
}

# ALB listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    
    forward {
      target_group {
        arn = aws_lb_target_group.wordpress_tg.arn
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-listener"
    Environment = var.environment
    Project = var.project_name
  }
}
