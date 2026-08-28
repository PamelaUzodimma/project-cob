output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Connection endpoint (host:port) of the database"
  value       = aws_db_instance.this.endpoint
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials -- applications should read credentials from here, never hardcode them"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  description = "ID of the database's security group"
  value       = aws_security_group.db.id
}
