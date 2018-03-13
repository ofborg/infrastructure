variable "hcloud_token" {}

variable "evaluator_sponsors" {
  default = [ "gleber", "lassulus", "shlevy", "shlevy"]
}

provider "hcloud" {
  token = "${var.hcloud_token}"
}


resource "hcloud_ssh_key" "default" {
  name = "ofborg infra provisioning key"
  public_key = "${file(var.provisioning_public_ssh_key)}"
}

resource "hcloud_server" "evaluator" {
  count        = 2
  name         = "eval-${count.index}-${element(var.evaluator_sponsors, count.index)}.ewr1.nix.ci"
  server_type  = "cx41"
  image        = "debian-9"
  ssh_keys     = [ "${hcloud_ssh_key.default.id}" ]

  provisioner "local-exec" {
    command = "./provisioner-nixos-kexec/convert-to-nixos.sh '${self.ipv4_address}' '${var.provisioning_public_ssh_key}' '${var.provisioning_private_ssh_key}'"
  }
}

resource "nixos_node" "evaluator" {
  count = "${hcloud_server.evaluator.count}"
  node_name = "eval-${count.index}"
  ip = "${hcloud_server.evaluator.*.ipv4_address[count.index]}"
  nix = <<NIX
    hetzner.plan = "${hcloud_server.evaluator.*.server_type[count.index]}";
    networking.hostName = "${hcloud_server.evaluator.*.name[count.index]}";

    roles.evaluator.enable = true;
  NIX
}
