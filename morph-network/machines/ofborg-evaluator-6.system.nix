{
  imports = [
    ({
      networking.hostName = "ofborg-evaluator-6";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.197.190";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::4";
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
        macAddress = "24:8a:07:e3:ce:00";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.132";
            }
          ];
          addresses = [
            {
              address = "147.75.197.191";
              prefixLength = 31;
            }
            {
              address = "10.99.98.133";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::5";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
    ({ networking.hostId = "6dbe8463"; }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/md-uuid-0f4b0f2b:5421862c:c4fc9594:ec3dc4df";
        }

      ];

      fileSystems = {

        "/" = {
          device = "/dev/disk/by-id/md-uuid-10969b74:70bfd51b:58300784:f0b3194f";
          fsType = "ext4";

        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-MICRON_M510DC_MTFDDAK480MBP_160811E3D5B8" "/dev/disk/by-id/ata-MICRON_M510DC_MTFDDAK480MBP_160811E3D35B" ];
    })
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
  ];
}
