provider "aws" {
  region = "ap-southeast-1"
}

locals {
  name   = "dev-${basename(path.cwd)}"
  region = "ap-south-east-1"

  vpc_cidr = "10.0.0.0/16"

  tags = {
    name    = local.name
    project = "peace-on-earth"
  }
}


