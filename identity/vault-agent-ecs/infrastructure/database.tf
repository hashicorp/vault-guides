resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "Allow inbound traffic to database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow inbound from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  ingress {
    description = "Allow inbound from HCP Vault"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.hcp_network_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "product_db" {
  name = "${var.name}-product-db"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "product_db" {
  family                   = "product-db"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.product_db.arn
  execution_role_arn       = aws_iam_role.product_db.arn
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  container_definitions = jsonencode([
    {
      name      = "product-db"
      image     = "hashicorpdemoapp/product-api-db:v0.0.22"
      essential = true
      portMappings = [
        {
          containerPort = 5432
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "POSTGRES_DB"
          value = "products"
        },
        {
          name  = "POSTGRES_USER"
          value = "${var.database_username}"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "${random_password.password.result}"
        },
      ]
    }
  ])
}

resource "aws_ecs_service" "product_db" {
  name            = "product-db"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.product_db.arn
  desired_count   = 1
  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.database.id]
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
  load_balancer {
    target_group_arn = aws_lb_target_group.product_db.arn
    container_name   = "product-db"
    container_port   = 5432
  }
}

