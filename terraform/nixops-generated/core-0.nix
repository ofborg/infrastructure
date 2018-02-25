{
  deployment.targetHost = "147.75.73.161";
  terraform.name = "core-0";
      packet.plan = "baremetal_0";
    roles.core.enable = true;
    networking = {
      hostName = "core0.ewr1.nix.ci";

      defaultGateway = {
        address = "147.75.73.160";
        interface = "bond0";
      };

      defaultGateway6 = {
        address = "2604:1380:0:3c00::";
        interface = "bond0";
      };

      bonds.bond0 = {
        driverOptions.mode = "balance-tlb";
        interfaces = [ "enp0s20f0" "enp0s20f1" ];
      };
      interfaces.bond0 = {
        useDHCP = true;
        ip4 = [
          { address = "147.75.73.161";
            prefixLength = 31;
          }
          { address = "10.99.147.129";
            prefixLength = 31;
          }
        ];
        ip6 = [
          { address = "2604:1380:0:3c00::1";
            prefixLength = 127;
          }
        ];
      };
    };
  
}
