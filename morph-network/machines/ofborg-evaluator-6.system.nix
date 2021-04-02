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
      networking.hostName = "ofborg-evaluator-6";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.105.24";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::2c";
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
        macAddress = "f4:52:14:70:31:70";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.172";
            }
          ];
          addresses = [
            {
              address = "147.75.105.25";
              prefixLength = 31;
            }
            {
              address = "10.99.98.173";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::2d";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/md-uuid-6d8bb510:a552b339:ea257f76:103631e8";
        }

      ];

      fileSystems = {

        "/" = {
          device = "/dev/disk/by-id/md-uuid-9aa07791:12357ae2:4d6796a0:6d3f361a";
          fsType = "ext4";

        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-SAMSUNG_MZ7KM480HAHP-00005_S2HSNX0H511704" "/dev/disk/by-id/ata-SAMSUNG_MZ7KM480HAHP-00005_S2HSNX0H511707" ];
    })
    ({ networking.hostId = "a34e9b10"; }
    )
  ];
}
