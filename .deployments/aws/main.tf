provider "aws" {
  region = "ap-southeast-1"
}

locals {
  project = "teammates"
  env     = "dev"
  name    = "${local.project}-${local.env}"
  region = "ap-southeast-1"

  tags = {
    Project     = local.project
    CreatedBy   = "terraform"
  }
}


