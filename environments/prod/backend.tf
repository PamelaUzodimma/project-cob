# Same state bucket + lock table as dev, different key -- this is what
# lets one bootstrap serve both environments without duplicating
# state infrastructure. Replace <ACCOUNT_ID> as done for dev.

terraform {
  backend "s3" {
    bucket         = "cob-terraform-state-194417786112"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cob-terraform-locks"
    encrypt        = true
  }
}
