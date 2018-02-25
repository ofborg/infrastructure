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

resource "packet_device" "core-0" {
  hostname         = "core0.ewr1.nix.ci"
  plan             = "baremetal_0"
  facility         = "ewr1"
  operating_system = "nixos_17_03"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.ofborg.id}"
}

resource "nixos_node" "core-0" {
  node_name = "core-0"
  ip = "${packet_device.core-0.network.0.address}"
  nix = <<NIX
    packet.plan = "${packet_device.core-0.plan}";
    roles.core.enable = true;
    networking = {
      hostName = "${packet_device.core-0.hostname}";

      defaultGateway = {
        address = "${packet_device.core-0.network.0.gateway}";
        interface = "bond0";
      };

      defaultGateway6 = {
        address = "${packet_device.core-0.network.1.gateway}";
        interface = "bond0";
      };

      bonds.bond0 = {
        driverOptions.mode = "balance-tlb";
        interfaces = [ "enp0s20f0" "enp0s20f1" ];
      };
      interfaces.bond0 = {
        useDHCP = true;
        ip4 = [
          { address = "${packet_device.core-0.network.0.address}";
            prefixLength = ${packet_device.core-0.network.0.cidr};
          }
          { address = "${packet_device.core-0.network.2.address}";
            prefixLength = ${packet_device.core-0.network.2.cidr};
          }
        ];
        ip6 = [
          { address = "${packet_device.core-0.network.1.address}";
            prefixLength = ${packet_device.core-0.network.1.cidr};
          }
        ];
      };
    };
  NIX
}
