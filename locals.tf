locals {
  asg_tags = merge(var.tags, { Name = "${var.name}-${var.env}" })
}
