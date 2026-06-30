output "vault_endpoint" {
  description = "HTTPS endpoint for the Vault API"
  value       = "https://${var.domain_name}"
}

output "vault_alb_dns" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.vault.dns_name
}

output "vault_alb_zone_id" {
  description = "Route53 zone ID of the ALB (for alias records)"
  value       = aws_lb.vault.zone_id
}

output "vault_sg_id" {
  description = "Security group ID attached to Vault tasks"
  value       = aws_security_group.vault.id
}

output "alb_sg_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for auto-unseal"
  value       = local.kms_key_arn
}

output "iam_role_arn" {
  description = "ARN of the Vault ECS task IAM role"
  value       = aws_iam_role.vault_task.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB storage backend table"
  value       = aws_dynamodb_table.vault_storage.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.vault.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vault.name
}
