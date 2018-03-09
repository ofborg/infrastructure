{
  deployment.targetHost = "147.75.74.109";
  terraform.name = "builder-1";
      packet.plan = "baremetal_0";
    networking.hostName = "builder-1-gustav.ewr1.nix.ci";

    roles.builder.enable = true;
    packet.network_data = ''
      [{"address":"147.75.74.109","cidr":"31","family":"4","gateway":"147.75.74.108","public":"1"},{"address":"2604:1380:0:3c00::9","cidr":"127","family":"6","gateway":"2604:1380:0:3c00::8","public":"1"},{"address":"10.99.147.135","cidr":"31","family":"4","gateway":"10.99.147.134","public":"0"}]
    '';
  
}
