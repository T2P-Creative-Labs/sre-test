output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.wordpress_alb.dns_name
}

output "alb_listener_arn" {
  description = "The ARN of the load balancer listener"
  value       = aws_lb_listener.front_end.arn
}

output "target_group_arn" {
  description = "ARN of the WordPress target group"
  value       = aws_lb_target_group.wordpress_tg.arn
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = var.alb_security_group_id
}
