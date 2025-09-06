provider "aws" {
  region = "us-east-1"
  profile = "avner"
  
  default_tags {
    tags = {
      project-relation = "VPC-TESTS"
      created-by       = "Avner Tzur"
      requested-by     = "avner.zur@gmail.com"
      environment-type = "dev"
      environment-name = "development"
      jira-tickets     = "THP-1234"
    }
  } # Default region, can be changed as needed
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-vpc-tfstate"
     
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "my-vpc-tfstate-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}