output "public_addresses" {
  value = "${aws_instance.server.*.public_ip}"
}

output "private_addresses" {
  value = "${aws_instance.server.*.private_ip}"
}
