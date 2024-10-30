terraform {
  backend "s3" {
    bucket = "cprabha"
    key    = "aws/terraform.tfstate"
    region = "ap-south-1"
  }
}

