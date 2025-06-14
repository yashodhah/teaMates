module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
  }

  services = {
    order-service = {
      cpu    = 512
      memory = 1024

      container_definitions = {
        order-service = {
          cpu       = 512
          memory    = 1024
          essential = true
          image = "${var.ecr_registry}/order-service:latest"

          port_mappings = [{
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          }]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
          }

          enable_cloudwatch_logging = true
        }
      }

      subnet_ids = module.vpc.private_subnets

      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["order-service"].arn
          container_name   = "order-service"
          container_port   = 8080
        }
      }
    }

    order-processing-service = {
      cpu    = 512
      memory = 1024

      container_definitions = {
        order-processing-service = {
          cpu       = 512
          memory    = 1024
          essential = true
          image = "${var.ecr_registry}/order-processing-service:latest"

          port_mappings = [{
            containerPort = 8081
            hostPort      = 8081
            protocol      = "tcp"
          }]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8081/actuator/health || exit 1"]
          }

          enable_cloudwatch_logging = true
        }
      }

      subnet_ids = module.vpc.private_subnets

      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 8081
          to_port                  = 8081
          protocol                 = "tcp"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = local.tags
}
