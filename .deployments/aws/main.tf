provider "aws" {
  region = "ap-southeast-1"
}

locals {
  project = "teammates"
  env     = "dev"
  name    = "${local.project}-${local.env}-vpc"
  region = "ap-southeast-1"

  vpc_cidr = "10.0.0.0/16"

  tags = {
    Project     = local.project
    CreatedBy   = "terraform"
  }
}


