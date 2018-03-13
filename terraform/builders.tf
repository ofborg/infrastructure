variable "linux_sponsors" {
  default = [ "gustav", "shlevy" ]
}

resource "packet_device" "builder" {
  count            = 1
  hostname         = "builder-${count.index}-${element(var.linux_sponsors, count.index)}.ewr1.nix.ci"
  plan             = "baremetal_0"
  facility         = "ewr1"
  operating_system = "nixos_17_03"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.ofborg.id}"
}

resource "nixos_node" "builder" {
  count = "${packet_device.builder.count}"
  node_name = "builder-${count.index}"
  ip = "${packet_device.builder.*.access_public_ipv4[count.index]}"
  nix = <<NIX
    packet.plan = "${packet_device.builder.*.plan[count.index]}";
    networking.hostName = "${packet_device.builder.*.hostname[count.index]}";

    roles.builder.enable = true;
    packet.network_data = ''
      ${jsonencode("${packet_device.builder.*.network[count.index]}")}
    '';
  NIX
}
