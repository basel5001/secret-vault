terraform {
  backend "s3" {
    bucket         = "xops-terraform-state"
    key            = "secret-vault/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "xops-terraform-locks"
  }
}
