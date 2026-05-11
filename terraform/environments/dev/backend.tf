terraform {
  backend "s3" {
    bucket         = "secure-gateway-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "secure-gateway-tfstate-lock"
  }
}
