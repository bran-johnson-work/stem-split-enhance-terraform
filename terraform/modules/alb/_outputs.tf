#modules/alb-bg/_outputs.tf
#alb
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}
output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)"
  value       = aws_lb.alb.zone_id
}
output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.alb.arn
}
output "alb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.alb.arn_suffix
}

#target-group
output "alb_target_group_arn" {
  description = "Amazon Resource Name (ARN) identifying your Target Group"
  value       = { for key, value in aws_lb_target_group.alb_target_group : key => value.arn }
}
output "alb_target_group_arn_suffix" {
  description = "Amazon Resource Name (ARN) suffix for use with CloudWatch Metrics"
  value       = { for key, value in aws_lb_target_group.alb_target_group : key => value.arn_suffix }
}
output "alb_target_group_name" {
  description = "Name of the target group"
  value       = { for key, value in aws_lb_target_group.alb_target_group : key => value.name }
}

#alb-listener
output "alb_listener_arn" {
  description = "Amazon Resource Name (ARN) identifying your ALB Listener"
  value       = { for key, value in aws_lb_listener.alb_listener : key => value.arn }
}
