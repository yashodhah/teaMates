module "sqs_queue" {
  source = "terraform-aws-modules/sqs/aws"

  # `.fifo` is automatically appended to the name
  # This also means that `use_name_prefix` cannot be used on FIFO queues
  name       = "${local.name}-orderPlaced"
  fifo_queue = true

  # Dead letter queue
  create_dlq = true
  redrive_policy = {
    # default is 5 for this module
    maxReceiveCount = 10
  }

  tags = local.tags
}
