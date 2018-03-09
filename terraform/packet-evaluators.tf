
resource "packet_device" "evaluator" {
  count            = 0 # WARNING: THESE ARE EXPENSIVE
  hostname         = "p-eval-${count.index}.ewr1.nix.ci"
  plan             = "baremetal_1"
  facility         = "ewr1"
  operating_system = "nixos_17_03"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.ofborg.id}"
}

resource "nixos_node" "eval" {
  count = "${packet_device.evaluator.count}"
  node_name = "p-eval-${count.index}"
  ip = "${packet_device.evaluator.*.access_public_ipv4[count.index]}"
  nix = <<NIX
    packet.plan = "${packet_device.evaluator.*.plan[count.index]}";
    networking.hostName = "${packet_device.evaluator.*.hostname[count.index]}";

    roles.evaluator.enable = true;
    packet.network_data = ''
      ${jsonencode("${packet_device.evaluator.*.network[count.index]}")}
    '';
  NIX
}
