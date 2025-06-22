terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6.0.0"
    }
  }

  # backend "s3" {
  #   bucket = "dev.labs.yashodha.terraform"
  #   key    = "dev"
  #   region = "ap-southeast-1"
  # }
}


