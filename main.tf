resource "template_file" "install" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    env        = "${var.env}"
    datacenter = "${var.consul_datacenter}"
  }
}

data "aws_ami" "consul" {
  most_recent = true
  owners      = ["753646501470"]

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:service_name"
    values = ["${var.service_name}"]
  }

  filter {
    name   = "tag:service_version"
    values = ["${var.service_version}"]
  }
}

// We launch Vault into an ASG so that it can properly bring them up for us.
resource "aws_autoscaling_group" "consul" {
  name                      = "consul - ${aws_launch_configuration.consul.name}"
  launch_configuration      = "${aws_launch_configuration.consul.name}"
  availability_zones        = ["${var.availability_zone}"]
  min_size                  = "${var.servers}"
  max_size                  = "${var.servers}"
  desired_capacity          = "${var.servers}"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${var.subnet}"]
  load_balancers            = ["${aws_elb.consul.id}"]

  tag {
    key                 = "Name"
    value               = "${lookup(var.resource_tags, "ClusterName")}-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "${lookup(var.resource_tags, "Owner")}"
    propagate_at_launch = true
  }

  tag {
    key                 = "TTL"
    value               = "${lookup(var.resource_tags, "TTL")}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "consul"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ConsulServer"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}

module "consul_instance_profile" {
  region        = "${var.region}"
  source        = "./instance-policy"
  resource_tags = "${var.resource_tags}"
}

resource "aws_launch_configuration" "consul" {
  image_id             = "${data.aws_ami.consul.id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  user_data            = "${template_file.install.rendered}"
  iam_instance_profile = "${module.consul_instance_profile.policy}"

  security_groups = [
    "${aws_security_group.consul.id}",
    "${aws_security_group.consul-nodes.id}",
  ]
}

// Security group for Vault allows SSH and HTTP access (via "tcp" in
// case TLS is used)
resource "aws_security_group" "consul" {
  name        = "consul-${var.env}"
  description = "Consul servers"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "consul-ssh" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

// This rule allows Vault HTTP API access to individual nodes, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "consul-http-api" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-egress" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Launch the ELB that is serving Vault. This has proper health checks
// to only serve healthy, unsealed Vaults.
resource "aws_elb" "consul" {
  name                        = "consul-${var.env}"
  connection_draining         = true
  connection_draining_timeout = 400
  internal                    = true
  subnets                     = ["${var.subnet}"]
  security_groups             = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 8500
    instance_protocol = "tcp"
    lb_port           = 8500
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8301
    instance_protocol = "tcp"
    lb_port           = 8301
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    target              = "TCP:8500"
    interval            = 15
  }
}

resource "aws_security_group" "elb" {
  name        = "consul-elb-${var.env}"
  description = "Consul ELB"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "consul-elb-http" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-elb-client" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "ingress"
  from_port         = 8301
  to_port           = 8301
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-elb-egress" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
