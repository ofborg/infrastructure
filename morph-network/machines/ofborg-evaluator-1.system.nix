{
  imports = [
    ({
      imports = [
        (
          {
            boot.kernelModules = [ "dm_multipath" "dm_round_robin" "ipmi_watchdog" ];
            services.openssh.enable = true;
          }
        )
        (
          {
            nixpkgs.config.allowUnfree = true;
            boot.initrd.availableKernelModules = [
              "ahci"
              "ehci_pci"
              "megaraid_sas"
              "mpt3sas"
              "sd_mod"
              "usbhid"
              "xhci_pci"
            ];

            boot.kernelModules = [ "kvm-intel" ];
            boot.kernelParams = [ "console=ttyS1,115200n8" ];
            boot.extraModulePackages = [ ];

            hardware.enableAllFirmware = true;
          }
        )
        (
          { lib, ... }:
          {
            boot.loader.grub.extraConfig = ''
              serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
              terminal_output serial console
              terminal_input serial console
            '';
            nix.maxJobs = lib.mkDefault 48;
          }
        )
      ];
    }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/md-uuid-501ea9d1:fb9e58a7:4b570ab3:35ee8a03";
        }

      ];

      fileSystems = {

        "/" = {
          device = "/dev/disk/by-id/md-uuid-16fed881:f485f0e1:c922d0c9:df42faec";
          fsType = "ext4";

        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-MZ7KM480HAHP00D3_S2VWNXAH200119" "/dev/disk/by-id/ata-MZ7KM480HAHP00D3_S2VWNXAH201062" ];
    })
    ({
      networking.hostName = "ofborg-evaluator-1";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.38.26";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::38";
        interface = "bond0";
      };
      networking.nameservers = [
        "147.75.207.207"
        "147.75.207.208"
      ];

      networking.bonds.bond0 = {
        driverOptions = {
          mode = "802.3ad";
          xmit_hash_policy = "layer3+4";
          lacp_rate = "fast";
          downdelay = "200";
          miimon = "100";
          updelay = "200";
        };

        interfaces = [
          "enp2s0"
          "enp2s0d1"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;
        macAddress = "f4:52:14:70:2e:70";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.184";
            }
          ];
          addresses = [
            {
              address = "147.75.38.27";
              prefixLength = 31;
            }
            {
              address = "10.99.98.185";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::39";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
    ({ networking.hostId = "5ed1736a"; }
    )
  ];
}
