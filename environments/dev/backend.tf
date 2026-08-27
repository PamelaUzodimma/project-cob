# BEGINNER NOTE: replace <ACCOUNT_ID> below with the value printed by
# `terraform output state_bucket_name` after you apply /bootstrap.
# The "key" is what makes dev and prod share one bucket safely — each
# environment writes to its own path inside it.

terraform {
  backend "s3" {
    bucket         = "cob-terraform-state-194417786112"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cob-terraform-locks"
    encrypt        = true
  }
}
