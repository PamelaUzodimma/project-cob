output "vpc_id" {
  value = module.networking.vpc_id
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "service_name" {
  value = module.compute.service_name
}
