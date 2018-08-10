{
  deployment.targetHost = "147.75.39.187";
  terraform.name = "core-1";
      packet.plan = "baremetal_0";
    networking.hostName = "core-1.ewr1.nix.ci";

    roles.core-v2.enable = true;
    packet.network_data = ''
      [{"address":"147.75.39.187","cidr":"31","family":"4","gateway":"147.75.39.186","public":"1"},{"address":"2604:1380:0:3c00::7","cidr":"127","family":"6","gateway":"2604:1380:0:3c00::6","public":"1"},{"address":"10.99.147.135","cidr":"31","family":"4","gateway":"10.99.147.134","public":"0"}]
    '';
  
}
