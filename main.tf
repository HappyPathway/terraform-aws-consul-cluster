resource "aws_instance" "server" {
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.servers}"
  security_groups = ["${aws_security_group.consul.id}"]
  subnet_id       = "${var.subnet}"

  connection {
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${var.ssh_private_key}"
  }

  tags = "${merge(map("Name", "${var.tagName}-${count.index}", "ConsulRole", "Server"), var.resource_tags)}"

  provisioner "file" {
    source      = "${path.module}/scripts/${lookup(var.service_conf, var.platform)}"
    destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
  }

  provisioner "file" {
    source      = "${var.consul_config}"
    destination = "/tmp/consul-config.json"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/consul-server-count",
      "echo ${aws_instance.server.0.private_ip} > /tmp/consul-server-addr",
      "echo ${var.consul_download_url} > /tmp/consul-download-url",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
      "${path.module}/scripts/service.sh",
      "${path.module}/scripts/ip_tables.sh",
    ]
  }
}
