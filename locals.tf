locals {
  asg_tags         = merge(var.tags, { Name = "${var.name}-${var.env}" })
  dynamic_asg_tags = [for k, v in local.asg_tags : tomap({ key = k, value = v })]
}
