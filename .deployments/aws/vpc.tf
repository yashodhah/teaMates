data "aws_iam_policy_document" "ecr_endpoint_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
}

data "aws_iam_policy_document" "sqs_endpoint_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
}



module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name = local.name
  cidr = "10.16.0.0/16"

  azs              = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets   = ["10.16.48.0/20", "10.16.112.0/20", "10.16.176.0/20"] # Web tier
  private_subnets  = ["10.16.32.0/20", "10.16.96.0/20", "10.16.160.0/20"]  # App tier
  database_subnets = ["10.16.16.0/20", "10.16.80.0/20", "10.16.144.0/20"]  # DB tier
  intra_subnets    = ["10.16.0.0/20", "10.16.64.0/20", "10.16.128.0/20"]   # Reserved tier

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false
  single_nat_gateway = false

  #   enable_vpn_gateway = true
  #
  #   enable_dhcp_options              = true
  #   dhcp_options_domain_name         = "service.consul"
  #   dhcp_options_domain_name_servers = ["127.0.0.1", "10.10.0.2"]

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  vpc_flow_log_iam_role_name            = "${local.name}-flow-log-role"
  vpc_flow_log_iam_role_use_name_prefix = false
  enable_flow_log                       = true
  create_flow_log_cloudwatch_log_group  = true
  create_flow_log_cloudwatch_iam_role   = true
  flow_log_max_aggregation_interval     = 60

  tags = local.tags
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.ecr_endpoint_policy.json
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.ecr_endpoint_policy.json
    },
    sqs = {
      service             = "sqs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.sqs_endpoint_policy.json
    }
  }

  tags = local.tags
}
