variable "aws_region" {
  type = "string"
}

variable "aws_access_key" {
  type = "string"
}

variable "aws_secret_key" {
  type = "string"
}

variable "root_domain" {
  type = "string"
}


provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

data "aws_route53_zone" "root" {
  name         = "${var.root_domain}"
}

resource "aws_route53_record" "root" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_public_ipv4}" ]
}

resource "aws_route53_record" "logs" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "logs.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_public_ipv4}" ]
}

resource "aws_route53_record" "events" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "events.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_public_ipv4}" ]
}

resource "aws_route53_record" "monitoring" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "monitoring.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_public_ipv4}" ]
}

resource "aws_route53_record" "webhook" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "webhook.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_public_ipv4}" ]
}

resource "aws_route53_record" "core" {
  count = "${packet_device.core.count}"
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${packet_device.core.*.hostname[count.index]}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core.*.access_private_ipv4[count.index]}" ]
}

resource "aws_route53_record" "builder" {
  count = "${packet_device.builder.count}"
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${packet_device.builder.*.hostname[count.index]}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.builder.*.access_private_ipv4[count.index]}" ]
}

resource "aws_route53_record" "evaluator" {
  count = "${hcloud_server.evaluator.count}"
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${hcloud_server.evaluator.*.name[count.index]}"
  type    = "A"
  ttl     = "300"
  records = [ "${hcloud_server.evaluator.*.ipv4_address[count.index]}" ]
}

resource "aws_route53_record" "evaluator-packet" {
  count = "${packet_device.evaluator.count}"
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${packet_device.evaluator.*.hostname[count.index]}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.evaluator.*.access_private_ipv4[count.index]}" ]
}