#Grafana
resource "aws_lb" "telemetry" {
  name            = "${var.env}-grafana"
  load_balancer_type = "application"
  internal        = false
  subnets         = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.telemetry-lb.id}"]
}

#Grafana
resource "aws_lb_target_group" "grafana" {
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"

  health_check {
    path     = "/api/health"
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = "${aws_lb.telemetry.arn}"
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.grafana.arn}"
    type             = "forward"
  }
}

#Envoy
resource "aws_lb" "envoy" {
  name            = "${var.env}-envoy"
  load_balancer_type = "network"
  internal        = false
  subnets         = ["${module.vpc.public_subnets}"]
}

resource "aws_lb_listener" "envoy_http" {
  load_balancer_arn = "${aws_lb.envoy.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.envoy_http.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "envoy_http" {
  port     = "8080"
  protocol = "TCP"
  vpc_id   = "${module.vpc.vpc_id}"

}

resource "aws_lb_listener" "envoy_https" {
  load_balancer_arn = "${aws_lb.envoy.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.envoy_https.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "envoy_https" {
  port     = "8443"
  protocol = "TCP"
  vpc_id   = "${module.vpc.vpc_id}"

}
