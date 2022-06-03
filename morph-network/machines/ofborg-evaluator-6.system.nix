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
        "mpt3sas"
        "nvme"
        "sd_mod"
        "xhci_pci"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.kernelParams = [ "console=ttyS1,115200n8" ];
      boot.extraModulePackages = [ ];

      hardware.enableAllFirmware = true;
    }
    )
    ({ lib, ... }:
      {
        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        nix.maxJobs = lib.mkDefault 64;
      }
    )
    ({
      swapDevices = [

      ];

      fileSystems = {

        "/boot/efi" = {
          device = "/dev/disk/by-id/ata-MTFDDAV240TDU_21433252038C-part1";
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

      boot.loader.efi.efiSysMountPoint = "/boot/efi";
    })
    ({ networking.hostId = "1e97b98c"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "ofborg-evaluator-6";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.50.252";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:45f1:400::";
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
          "enp65s0f0"
          "enp65s0f1"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;
        macAddress = "b4:96:91:d1:fc:66";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.68.6.128";
            }
          ];
          addresses = [
            {
              address = "147.75.50.253";
              prefixLength = 31;
            }
            {
              address = "10.68.6.129";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:45f1:400::1";
              prefixLength = 127;
            }
          ];
        };
      };
    }
    )
  ];
}
