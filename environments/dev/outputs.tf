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

output "demo_db_endpoint" {
  value = module.database_demo.db_endpoint
}

output "demo_db_secret_arn" {
  value = module.database_demo.secret_arn
}

output "demo_glue_database" {
  value = module.data_platform_demo.glue_database_name
}

output "demo_athena_workgroup" {
  value = module.data_platform_demo.athena_workgroup_name
}
