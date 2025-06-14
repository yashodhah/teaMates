module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"
  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "default"
      }
    }
  }

  target_groups = {
    order-service = {
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      health_check = {
        enabled  = true
        path     = "/actuator/health"
        protocol = "HTTP"
      }
    }

    order-processing-service = {
      backend_protocol = "HTTP"
      backend_port     = 8081
      target_type      = "ip"
      health_check = {
        enabled  = true
        path     = "/actuator/health"
        protocol = "HTTP"
      }
    }

    default = {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      create_attachment = false
    }
  }

  tags = local.tags
}
