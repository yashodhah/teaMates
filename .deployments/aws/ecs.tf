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

          environment = [
            { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
            { name = "SQS_QUEUE_NAME", value = "mydrugs_orderPlaced" }
          ]

          port_mappings = [{
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          }]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
          }

          enable_cloudwatch_logging = true
          readonly_root_filesystem = false
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

      tasks_iam_role_name        = "${local.name}-order-service-task-role"
      tasks_iam_role_description = "IAM role for order-service ECS task to send messages to SQS"

      tasks_iam_role_statements = [
        {
          actions = [
            "sqs:SendMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl"
          ]
          resources = [
            module.sqs_queue.queue_arn  # Reference to your SQS module's output
          ]

        },
        {
          actions = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          resources = ["*"]
        },
        {
          actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          resources = ["*"]
        }
      ]
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
          environment = [
            { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
            { name = "SQS_QUEUE_NAME", value = "mydrugs_orderPlaced" }
          ]

          port_mappings = [{
            containerPort = 8082
            hostPort      = 8082
            protocol      = "tcp"
          }]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8082/actuator/health || exit 1"]
          }

          enable_cloudwatch_logging = true
          readonly_root_filesystem = false
        }
      }

      subnet_ids = module.vpc.private_subnets

      security_group_rules = {
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      tasks_iam_role_name        = "${local.name}-order-process-task-role"
      tasks_iam_role_description = "IAM role for order-processing-service ECS task to poll messages from SQS"

      tasks_iam_role_statements = [
        {
          actions = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl"
          ]
          resources = [
            module.sqs_queue.queue_arn
          ]
        },
        {
          actions = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          resources = ["*"]
        },
        {
          actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          resources = ["*"]
        }
      ]
    }
  }

  tags = local.tags
}
