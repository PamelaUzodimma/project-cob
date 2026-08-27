# outputs.tf
#
# BEGINNER NOTE: outputs are how OTHER modules plug into this one.
# e.g. the RDS module will take "private_subnet_ids" as an input so it
# knows where to place the database. This is the "clean interface"
# the brief asks for — consumers never need to know cidrsubnet math
# or how many route tables exist.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "default_security_group_id" {
  description = "ID of the baseline deny-by-default security group"
  value       = aws_security_group.default_deny.id
}
