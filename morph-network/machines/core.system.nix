{
  imports = [
    ({
      swapDevices = [

      ];

      fileSystems = {

        "/boot" = {
          device = "/dev/disk/by-id/ata-Micron_5200_MTFDDAK480TDN_200325F2200A-part2";
          fsType = "vfat";

        };


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


        "/home" = {
          device = "npool/home";
          fsType = "zfs";
          options = [ "defaults" ];
        };


        "/var" = {
          device = "npool/var";
          fsType = "zfs";
          options = [ "defaults" ];
        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-Micron_5200_MTFDDAK480TDN_200325F2200A" "/dev/disk/by-id/ata-Micron_5200_MTFDDAK480TDN_200325F21F8F" ];
    })
    ({
      networking.hostName = "ofborg-core";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "136.144.57.216";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:45f1:400::2";
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
          "enp1s0f0np0"
          "enp1s0f1np1"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;
        macAddress = "1c:34:da:42:74:c8";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.68.6.130";
            }
          ];
          addresses = [
            {
              address = "136.144.57.217";
              prefixLength = 31;
            }
            {
              address = "10.68.6.131";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:45f1:400::3";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
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
            boot.initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "usbhid"
              "sd_mod"
            ];

            boot.kernelModules = [ "kvm-intel" ];
            boot.kernelParams = [ "console=ttyS1,115200n8" ];
            boot.extraModulePackages = [ ];
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
            nix.maxJobs = lib.mkDefault 16;
          }
        )
      ];
    }
    )
    ({ networking.hostId = "5c89f81c"; }
    )
  ];
}
