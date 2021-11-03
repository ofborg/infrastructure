{
  imports = [
    ({
      boot.kernelModules = [ "dm_multipath" "dm_round_robin" "ipmi_watchdog" ];
      services.openssh.enable = true;
    }
    )
    ({
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
    ({ lib, ... }:
      {
        boot.loader.grub.extraConfig = ''
          serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
          terminal_output serial console
          terminal_input serial console
        '';
        nix.maxJobs = lib.mkDefault 48;
      }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/ata-MZ7KM480HAHP00D3_S2VWNXAH200119-part2";
        }

      ];

      fileSystems = {

        "/" = {
          device = "npool/root";
          fsType = "zfs";
          options = [ "defaults" ];
        };


        "/nix" = {
          device = "npool/nix";
          fsType = "zfs";
          options = [ "defaults" ];
        };


        "/var" = {
          device = "npool/var";
          fsType = "zfs";
          options = [ "defaults" ];
        };


        "/home" = {
          device = "npool/home";
          fsType = "zfs";
          options = [ "defaults" ];
        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-MZ7KM480HAHP00D3_S2VWNXAH200119" ];
    })
    ({ networking.hostId = "87998062"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "ofborg-evaluator-0";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.198.100";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::14";
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
              via = "10.99.98.148";
            }
          ];
          addresses = [
            {
              address = "147.75.198.101";
              prefixLength = 31;
            }
            {
              address = "10.99.98.149";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::15";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
  ];
}
