variable "packet_key" {
  type = "string"
}

variable "provisioning_public_ssh_key" {
  type = "string"
}

variable "provisioning_private_ssh_key" {
  type = "string"
}

provider "packet" {
  auth_token = "${var.packet_key}"
}

provider "nixos" {
  root = "./nixops-generated"
}

resource "packet_project" "ofborg" {
  name           = "ofborg-production"
}

resource "packet_ssh_key" "provisioning-key" {
  name       = "ofborg-provisioning-key"
  public_key = "${file("${var.provisioning_public_ssh_key}")}"
}

resource "packet_device" "core" {
  count            = 1 # nixops code doesn't support > 1 right now
  hostname         = "core-${count.index}.ewr1.nix.ci"
  plan             = "baremetal_0"
  facilities       = [ "ewr1" ]
  operating_system = "nixos_17_03"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.ofborg.id}"
}

resource "nixos_node" "core" {
  count = "${packet_device.core.count}"
  node_name = "core-${count.index}"
  ip = "${packet_device.core.*.access_public_ipv4[count.index]}"
  nix = <<NIX
    packet.plan = "${packet_device.core.*.plan[count.index]}";
    networking.hostName = "${packet_device.core.*.hostname[count.index]}";

    roles.core.enable = true;
    packet.network_data = ''
      ${jsonencode("${packet_device.core.*.network[count.index]}")}
    '';
  NIX
}
