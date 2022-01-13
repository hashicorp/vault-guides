resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.name}-services"
}

locals {
  product_api_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "product"
    }
  }
}