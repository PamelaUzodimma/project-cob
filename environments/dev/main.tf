# environments/dev/main.tf
#
# BEGINNER NOTE: this file should contain almost NO logic — just calls
# to modules from ../../modules, with dev-specific variable values.
# If you ever feel tempted to write a resource block directly in here,
# stop: that resource probably belongs inside a module instead.

module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = "dev"
  owner_team  = var.owner_team

  vpc_cidr           = "10.0.0.0/16"
  az_count           = 2
  enable_nat_gateway = false # save ~$32/mo in dev; flip true if you need private-subnet internet egress
}

module "iam_ecs_task_demo" {
  source = "../../modules/iam"

  project        = var.project
  environment    = "dev"
  owner_team     = var.owner_team
  role_purpose   = "ecs-task-demo"
  assume_service = "ecs-tasks.amazonaws.com"

  permission_statements = [
    {
      sid       = "ReadWriteDemoBucket"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::cob-dev-demo-*", "arn:aws:s3:::cob-dev-demo-*/*"]
    }
  ]
}

module "storage_demo" {
  source = "../../modules/storage"

  project        = var.project
  owner_team     = var.owner_team
  environment    = "dev"
  bucket_purpose = "demo"
}

module "compute_demo" {
  source = "../../modules/compute-ecs"

  project      = var.project
  environment  = "dev"
  owner_team   = var.owner_team
  service_name = "demo-web"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  container_image = "public.ecr.aws/nginx/nginx:latest"
  container_port  = 80
  cpu             = 256
  memory          = 512
  desired_count   = 1

  task_role_arn = module.iam_ecs_task_demo.role_arn

  ingress_cidr_blocks = [module.networking.vpc_cidr]
}