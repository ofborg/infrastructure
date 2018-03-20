{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.packet;

  toNetworkCfg = conf:
    let
      trace = x: builtins.trace x x;
      ipv4Blocks = lib.filter (block: block.family == "4") conf;
      ipv6Blocks = lib.filter (block: block.family == "6") conf;

      publicIPs = lib.filter (block: block.public == "1");
      gateways = map (block: block.gateway);
      addresses = map (block: block.address);

      interfaceIPs = map (block: {
        address = block.address;
        prefixLength = lib.toInt block.cidr;
      });
    in {
      deployment.targetHost = lib.mkForce (lib.head (addresses (publicIPs ipv4Blocks)));
      networking = {
        defaultGateway = {
          interface = "bond0";
          address = lib.head (gateways (publicIPs ipv4Blocks));
        };

        defaultGateway6 = {
          interface = "bond0";
          address = lib.head (gateways (publicIPs ipv6Blocks));
        };

        interfaces.bond0 = {
          ip4 = interfaceIPs ipv4Blocks;
          ip6 = interfaceIPs ipv6Blocks;
        };
      };
    };
in {
  options = {
    packet = {
      plan = mkOption {
        type = types.enum [ "none" "baremetal_0" "baremetal_1" ];
        default = "none";
      };
      network_data = mkOption {
        type = types.string;
      };
    };
  };

  config = mkMerge [
    (mkIf ("${cfg.plan}" != "none") (toNetworkCfg (builtins.fromJSON cfg.network_data)))
    (mkIf ("${cfg.plan}" == "none") {})
    (mkIf ("${cfg.plan}" == "baremetal_0") {
      boot = {
        initrd.availableKernelModules = [
          "ehci_pci" "ahci" "usbhid" "sd_mod"
        ];
        kernelModules = [ "kvm-intel" ];
        kernelParams =  [ "console=ttyS1,115200n8" ];
        extraModulePackages = [ ];
        loader.grub.devices = [ "/dev/sda" ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      hardware.enableAllFirmware = true;
      nix.maxJobs = 4;
      nix.gc_free_gb = 50;

      networking = {
        bonds.bond0 = {
          driverOptions.mode = "balance-tlb";
          interfaces = [ "enp0s20f0" "enp0s20f1" ];
        };
      };
    })
    (mkIf ("${cfg.plan}" == "baremetal_1") {
      boot = {
        supportedFilesystems = [ "zfs" ];
        initrd.availableKernelModules = [
          "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"
        ];

        kernelModules = [ "kvm-intel" ];
        kernelParams =  [ "console=ttyS1,115200n8" ];
        extraModulePackages = [ ];
        loader.grub.zfsSupport = true;
        loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];
      };

      hardware.enableAllFirmware = true;

      services.zfs.autoScrub.enable = true;
      fileSystems."/" = {
        device = "rpool/root/nixos";
        fsType = "zfs";
      };

      nix.maxJobs = 8;
      nix.gc_free_gb = 60;

      networking = {
        hostId = "aaaaaaaa";
        bonds.bond0 = {
          driverOptions.mode = "802.3ad";
          interfaces = [ "enp1s0f0" "enp1s0f1" ];
        };
      };
    })
  ];
}
