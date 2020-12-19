{
  deployment.targetHost = "147.75.199.209";
  terraform.name = "core-0";
      packet.plan = "baremetal_0";
    networking.hostName = "core-0.ewr1.nix.ci";

    roles.core.enable = true;
    packet.network_data = ''
      [{"address":"147.75.199.209","cidr":"31","family":"4","gateway":"147.75.199.208","public":"1"},{"address":"2604:1380:0:3c00::3","cidr":"127","family":"6","gateway":"2604:1380:0:3c00::2","public":"1"},{"address":"10.99.147.131","cidr":"31","family":"4","gateway":"10.99.147.130","public":"0"}]
    '';
  
}
