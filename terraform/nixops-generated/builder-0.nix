{
  deployment.targetHost = "147.75.196.61";
  terraform.name = "builder-0";
      packet.plan = "baremetal_0";
    networking.hostName = "builder-0-gustav.ewr1.nix.ci";

    roles.builder.enable = true;
    packet.network_data = ''
      [{"address":"147.75.196.61","cidr":"31","family":"4","gateway":"147.75.196.60","public":"1"},{"address":"2604:1380:0:3c00::5","cidr":"127","family":"6","gateway":"2604:1380:0:3c00::4","public":"1"},{"address":"10.99.147.133","cidr":"31","family":"4","gateway":"10.99.147.132","public":"0"}]
    '';
  
}
