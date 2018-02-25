{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.packet;
in {
  options = {
    packet = {
      plan = mkOption {
        type = types.enum [ "none" "baremetal_0" ];
        default = "none";
      };
    };
  };

  config = mkMerge [
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
    })
  ];
}
