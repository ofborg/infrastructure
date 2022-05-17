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
          device = "/dev/disk/by-id/ata-Micron_5100_MTFDDAK480TCC_171616D4DE77-part2";
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

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-Micron_5100_MTFDDAK480TCC_171616D4DE77" ];
    })
    ({ networking.hostId = "d067d48a"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "ofborg-evaluator-6";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "145.40.65.244";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::";
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
          "enp5s0f0np0"
          "enp5s0f1np1"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;
        macAddress = "0c:c4:7a:d6:67:a0";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.128";
            }
          ];
          addresses = [
            {
              address = "145.40.65.245";
              prefixLength = 31;
            }
            {
              address = "10.99.98.129";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::1";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
  ];
}
