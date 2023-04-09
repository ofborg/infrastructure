output "hostname" {
  value = metal_device.evaluator.hostname
}

output "public_ipv4" {
  # value = cidrhost(metal_reserved_ip_block.evaluator_block.cidr_notation, 0)
  value = metal_device.evaluator.access_public_ipv4
}
