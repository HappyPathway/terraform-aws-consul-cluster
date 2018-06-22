output "public_addresses" {
  value = "${aws_instance.server.*.public_ip}"
}

output "private_addresses" {
  value = "${aws_instance.server.*.private_ip}"
}


output "security_group" {
  value = "${aws_security_group.consul.id}"
}