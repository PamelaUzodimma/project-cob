# environments/prod/main.tf
#
# BEGINNER NOTE: compare this file to environments/dev/main.tf. Same
# modules, same structure -- the ONLY differences are values that
# genuinely should differ between dev and prod (NAT enabled, Multi-AZ,
# instance sizing, snapshot behavior). This is what "reusable across
# environments without duplicating infrastructure code" looks like in
# practice: zero copy-pasted resource logic, only copy-pasted (and
# intentionally-varied) module CALLS.
#
# This environment is written and validated (`terraform plan` succeeds)
# but intentionally NOT applied as part of this submission -- documented
# as a known scope decision, see docs/decisions/.

module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = "prod"
  owner_team  = var.owner_team

  vpc_cidr           = "10.2.0.0/16"
  az_count           = 3     # prod: spread across 3 AZs, not 2
  enable_nat_gateway = true  # prod: private subnets need reliable outbound
}

module "iam_ecs_task" {
  source = "../../modules/iam"

  project        = var.project
  environment    = "prod"
  owner_team     = var.owner_team
  role_purpose   = "ecs-task-demo"
  assume_service = "ecs-tasks.amazonaws.com"

  permission_statements = [
    {
      sid       = "ReadWriteDemoBucket"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::cob-prod-demo-*", "arn:aws:s3:::cob-prod-demo-*/*"]
    }
  ]
}

module "storage" {
  source = "../../modules/storage"

  project        = var.project
  environment    = "prod"
  owner_team     = var.owner_team
  bucket_purpose = "demo"

  # prod: keep more history, transition to cheap storage sooner
  noncurrent_version_expiration_days = 365
  transition_to_ia_days              = 14
}

module "compute" {
  source = "../../modules/compute-ecs"

  project      = var.project
  environment  = "prod"
  owner_team   = var.owner_team
  service_name = "demo-web"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  container_image = "public.ecr.aws/nginx/nginx:latest"
  container_port  = 80
  cpu             = 512   # prod: more headroom than dev's 256
  memory          = 1024  # prod: more headroom than dev's 512
  desired_count   = 2     # prod: run 2 copies for availability, not 1

  task_role_arn       = module.iam_ecs_task.role_arn
  ingress_cidr_blocks = [module.networking.vpc_cidr]

  log_retention_days = 90 # prod: keep logs longer than dev's 30
}

module "database" {
  source = "../../modules/database-rds"

  project     = var.project
  environment = "prod"
  owner_team  = var.owner_team
  db_purpose  = "demo"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  allowed_security_group_ids = [module.compute.security_group_id]

  engine                 = "postgres"
  engine_version          = "16.4"
  instance_class          = "db.t3.small" # prod: bigger than dev's db.t3.micro
  multi_az                = true          # prod: HA, unlike dev
  backup_retention_days   = 30            # prod: longer than dev's default 7
  skip_final_snapshot     = false         # prod: NEVER skip -- always keep a final snapshot
}

module "data_platform" {
  source = "../../modules/data-platform"

  project      = var.project
  environment  = "prod"
  owner_team   = var.owner_team
  dataset_name = "demo"

  source_bucket_name = module.storage.bucket_id
  source_bucket_arn  = module.storage.bucket_arn
  source_prefix      = "raw/"

  enable_crawler   = true
  crawler_schedule = "cron(0 6 * * ? *)" # prod: daily 6am UTC, unlike dev's on-demand
}
