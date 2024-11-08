# Create ssl cert from acm for your hostname
resource "aws_lb" "web_alb" {
  name                             = "${local.organisation}-web-alb"
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.web_alb_sg.id]
  enable_cross_zone_load_balancing = true

  # Include all three public subnets
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
    aws_subnet.public_subnet_c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${local.organisation}-web-alb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name        = "${local.organisation}-web-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.organisation}-web-tg"
  }
}

resource "aws_lb_listener" "web_listener_https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "placeholder_for_ssl_cert" # Replace with your ACM certificate ARN
  # certificate_arn   = "arn:aws:acm:us-west-2:123456789012:certificate/your-certificate-id" # Replace with your ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

  tags = {
    Name = "${local.organisation}-WebListenerHTTPS"
  }
}

# resource "aws_lb_listener_rule" "web_listener_rule" {
#   listener_arn = aws_lb_listener.web_listener_https.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_tg.arn
#   }

#   condition {
#     field  = "path-pattern"
#     values = ["/*"]
#   }
# }
