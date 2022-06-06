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
        boot.loader.grub.extraConfig = ''
          serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
          terminal_output serial console
          terminal_input serial console
        '';
        nix.maxJobs = lib.mkDefault 64;
      }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/ata-SSDSCKKB240G8R_PHYH121603YT240J-part2";
        }

      ];

      fileSystems = {

        "/" = {
          device = "/dev/disk/by-id/ata-SSDSCKKB240G8R_PHYH121603YT240J-part3";
          fsType = "ext4";

        };

      };

      boot.loader.grub.devices = [ "/dev/disk/by-id/ata-SSDSCKKB240G8R_PHYH121603YT240J" ];
    })
    ({ networking.hostId = "06b4b66e"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "ofborg-evaluator-0";
      networking.useNetworkd = true;


      systemd.network.networks."40-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig = {
          RequiredForOnline = "carrier";
          MACAddress = "40:a6:b7:72:5f:90";
        };
        networkConfig.LinkLocalAddressing = "no";
        dns = [
          "147.75.207.207"
          "147.75.207.208"
        ];
      };


      boot.extraModprobeConfig = "options bonding max_bonds=0";
      systemd.network.netdevs = {
        "10-bond0" = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond0";
          };
          bondConfig = {
            Mode = "802.3ad";
            LACPTransmitRate = "fast";
            TransmitHashPolicy = "layer3+4";
            DownDelaySec = 0.2;
            UpDelaySec = 0.2;
            MIIMonitorSec = 0.1;
          };
        };
      };


      systemd.network.networks."30-enp65s0f0" = {
        matchConfig = {
          Name = "enp65s0f0";
          PermanentMACAddress = "40:a6:b7:72:5f:90";
        };
        networkConfig.Bond = "bond0";
      };


      systemd.network.networks."30-enp65s0f1" = {
        matchConfig = {
          Name = "enp65s0f1";
          PermanentMACAddress = "40:a6:b7:72:5f:91";
        };
        networkConfig.Bond = "bond0";
      };



      systemd.network.networks."40-bond0".addresses = [
        {
          addressConfig.Address = "147.28.147.247/31";
        }
        {
          addressConfig.Address = "2604:1380:45f1:400::f/127";
        }
        {
          addressConfig.Address = "10.68.6.143/31";
        }
      ];
      systemd.network.networks."40-bond0".routes = [
        {
          routeConfig.Gateway = "147.28.147.246";
        }
        {
          routeConfig.Gateway = "2604:1380:45f1:400::e";
        }
        {
          routeConfig.Gateway = "10.68.6.142";
        }
      ];
    }
    )
  ];
}
