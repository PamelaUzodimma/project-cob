output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.this.name
}

output "crawler_name" {
  description = "Name of the Glue crawler (empty if enable_crawler = false)"
  value       = var.enable_crawler ? aws_glue_crawler.this[0].name : null
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup -- analysts should query using this workgroup, not 'primary'"
  value       = aws_athena_workgroup.this.name
}

output "athena_results_bucket" {
  description = "S3 bucket where Athena writes query results"
  value       = aws_s3_bucket.athena_results.id
}
