output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "demo_role_arn" {
  value = module.iam_ecs_task_demo.role_arn
}

output "demo_bucket_id" {
  value = module.storage_demo.bucket_id
}

output "demo_service_name" {
  value = module.compute_demo.service_name
}
