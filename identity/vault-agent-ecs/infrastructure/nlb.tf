resource "aws_security_group_rule" "nlb_to_ecs" {
  type              = "ingress"
  description       = "Allow access from product-db NLB to database"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.database.id
}

resource "aws_lb" "nlb" {
  name                       = "${var.name}-product-db"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = module.vpc.private_subnets
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "product_db" {
  name        = "product-db"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "product_db" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "5432"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_db.arn
  }
}
