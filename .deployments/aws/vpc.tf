module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name = local.name
  cidr = local.vpc_cidr

  azs              = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets   = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20"]   # Web tier
  private_subnets  = ["10.16.48.0/20", "10.16.64.0/20", "10.16.80.0/20"]  # App tier
  database_subnets = ["10.16.96.0/20", "10.16.112.0/20", "10.16.128.0/20"]# DB tier
  intra_subnets    = ["10.16.144.0/20", "10.16.160.0/20", "10.16.176.0/20"]# Reserved

  create_database_subnet_group  = true
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

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
