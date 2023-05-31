resource "aws_security_group" "sg" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "APP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allow_app_cidr
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-sg" })
}


resource "aws_launch_template" "template" {
  name_prefix            = "${var.name}-${var.env}-lt"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.name}-${var.env}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]


  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.asg_tags
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }

}

resource "aws_lb_target_group" "main" {
  name     = "${var.name}-${var.env}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags     = merge(var.tags, { Name = "${var.name}-${var.env}-tg" })
}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = var.listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = [local.dns_name]
    }
  }
}

resource "aws_route53_record" "main" {
  zone_id = var.domain_id
  name    = local.dns_name
  type    = "CNAME"
  ttl     = 30
  records = [var.lb_dns_name]
}





