output "autoscaling_group_name" {
  value = aws_autoscaling_group.web.name
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "kms_key_id" {
  value = aws_kms_key.main.id
}

# Output the KMS key ARN
output "kms_key_arn" {
  value = aws_kms_key.main.arn
}
