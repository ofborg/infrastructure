{
  deployment.targetHost = "147.75.64.189";
  terraform.name = "core-1";
      packet.plan = "baremetal_0";
    networking.hostName = "core-1.ewr1.nix.ci";

    roles.core-v2.enable = true;
    packet.network_data = ''
      [{"address":"147.75.64.189","cidr":"31","family":"4","gateway":"147.75.64.188","public":"1"},{"address":"2604:1380:0:3c00::1","cidr":"127","family":"6","gateway":"2604:1380:0:3c00::","public":"1"},{"address":"10.99.147.129","cidr":"31","family":"4","gateway":"10.99.147.128","public":"0"}]
    '';
  
}
