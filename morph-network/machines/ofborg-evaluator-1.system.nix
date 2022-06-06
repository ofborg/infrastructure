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
          device = "/dev/disk/by-id/ata-MTFDDAV240TDU_21433234B0F7-part2";
        }

      ];

      fileSystems = {

        "/boot/efi" = {
          device = "/dev/disk/by-id/ata-MTFDDAV240TDU_21433234B0F7-part1";
          fsType = "vfat";

        };


        "/" = {
          device = "/dev/disk/by-id/ata-MTFDDAV240TDU_21433234B0F7-part3";
          fsType = "ext4";

        };

      };

      boot.loader.efi.efiSysMountPoint = "/boot/efi";
    })
    ({ networking.hostId = "afe2daf8"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "ofborg-evaluator-1";
      networking.useNetworkd = true;


      systemd.network.networks."40-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig = {
          RequiredForOnline = "carrier";
          MACAddress = "b4:96:91:d1:fb:f4";
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
          PermanentMACAddress = "b4:96:91:d1:fb:f4";
        };
        networkConfig.Bond = "bond0";
      };


      systemd.network.networks."30-enp65s0f1" = {
        matchConfig = {
          Name = "enp65s0f1";
          PermanentMACAddress = "b4:96:91:d1:fb:f5";
        };
        networkConfig.Bond = "bond0";
      };



      systemd.network.networks."40-bond0".addresses = [
        {
          addressConfig.Address = "147.75.61.233/31";
        }
        {
          addressConfig.Address = "2604:1380:45f1:400::b/127";
        }
        {
          addressConfig.Address = "10.68.6.139/31";
        }
      ];
      systemd.network.networks."40-bond0".routes = [
        {
          routeConfig.Gateway = "147.75.61.232";
        }
        {
          routeConfig.Gateway = "2604:1380:45f1:400::a";
        }
        {
          routeConfig.Gateway = "10.68.6.138";
        }
      ];
    }
    )
  ];
}
