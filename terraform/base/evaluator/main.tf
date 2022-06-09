resource "metal_reserved_ip_block" "evaluator_block" {
  project_id = var.project_id
  metro      = var.metro
  quantity   = 1
}

resource "metal_device" "evaluator" {
  project_id       = var.project_id
  hostname         = var.hostname
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = var.plan
  metro            = var.metro
  user_data        = var.user_data
  ipxe_script_url  = var.ipxe_script_url
  always_pxe       = false
  tags             = var.tags

  ip_address {
    type            = "public_ipv4"
    cidr            = 32
    reservation_ids = [metal_reserved_ip_block.evaluator_block.id]
  }

  # You can supply one ip_address block per IP address type. If you use
  # the ip_address you must always pass a block for private_ipv4.
  ip_address {
    type = "private_ipv4"
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}
