# examples/web-app-with-datastore/main.tf
#
# Reference example: a team provisioning a full web app + datastore
# stack using ONLY COB module calls. See README.md for the composition
# graph and rationale.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  project     = "acme-webapp"
  environment = "dev"
  owner_team  = "application-engineering"
}

# 1. Network foundation
module "networking" {
  source = "../../modules/networking"

  project     = local.project
  environment = local.environment
  owner_team  = local.owner_team

  vpc_cidr           = "10.1.0.0/16"
  az_count           = 2
  enable_nat_gateway = false
}

# 2. Application's own IAM role -- scoped to exactly what it needs
module "app_iam" {
  source = "../../modules/iam"

  project        = local.project
  environment    = local.environment
  owner_team     = local.owner_team
  role_purpose   = "web-app-task"
  assume_service = "ecs-tasks.amazonaws.com"

  permission_statements = [
    {
      sid       = "AppBucketAccess"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      resources = [module.storage.bucket_arn, "${module.storage.bucket_arn}/*"]
    }
  ]
}

# 3. Object storage for user uploads
module "storage" {
  source = "../../modules/storage"

  project        = local.project
  environment    = local.environment
  owner_team     = local.owner_team
  bucket_purpose = "uploads"
}

# 4. The application itself, running on Fargate
module "web_app" {
  source = "../../modules/compute-ecs"

  project      = local.project
  environment  = local.environment
  owner_team   = local.owner_team
  service_name = "web-app"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  container_image = "public.ecr.aws/nginx/nginx:latest" # replace with real app image
  container_port  = 80
  cpu             = 512
  memory          = 1024
  desired_count   = 2

  task_role_arn       = module.app_iam.role_arn
  ingress_cidr_blocks = [module.networking.vpc_cidr]
}

# 5. Application database
module "database" {
  source = "../../modules/database-rds"

  project     = local.project
  environment = local.environment
  owner_team  = local.owner_team
  db_purpose  = "primary"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  allowed_security_group_ids = [module.web_app.security_group_id]

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t3.micro"
  multi_az       = false
}

# 6. Analytics access to uploaded data
module "analytics" {
  source = "../../modules/data-platform"

  project      = local.project
  environment  = local.environment
  owner_team   = local.owner_team
  dataset_name = "uploads"

  source_bucket_name = module.storage.bucket_id
  source_bucket_arn  = module.storage.bucket_arn
  source_prefix      = "processed/"

  enable_crawler = true
}
