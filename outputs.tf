output "cluster" {
  value = "${aws_elb.consul.dns_name}"
}

output "security_group" {
  value = "${aws_security_group.consul.id}"
}
