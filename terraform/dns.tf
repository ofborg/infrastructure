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

data "dns_a_record_set" "gscio" {
  host = "nix.gsc.io"
}

resource "aws_route53_record" "root" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${data.dns_a_record_set.gscio.addrs.0}" ]
}

resource "aws_route53_record" "logs" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "logs.${data.aws_route53_zone.root.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [ "nix.gsc.io" ]
}

resource "aws_route53_record" "events" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "events.${data.aws_route53_zone.root.name}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core-0.network.0.address}" ]
}

resource "aws_route53_record" "core-0" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${packet_device.core-0.hostname}"
  type    = "A"
  ttl     = "300"
  records = [ "${packet_device.core-0.network.2.address}" ]
}