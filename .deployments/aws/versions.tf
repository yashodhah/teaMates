terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }
  }

  backend "s3" {
    bucket = "dev.labs.yashodha.terraform"
    key    = "dev"
    region = "ap-southeast-1"
  }
}


