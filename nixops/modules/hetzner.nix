{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.hetzner;
in {
  options = {
    hetzner = {
      plan = mkOption {
        type = types.enum [ "none" "cx41" ];
        default = "none";
      };
    };
  };


  config = mkMerge [
    (mkIf ("${cfg.plan}" == "none") {})
    (mkIf ("${cfg.plan}" != "none") {
      # <nixpkgs/nixos/modules/profiles/qemu-guest.nix>

      boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
      boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

      boot.initrd.postDeviceCommands =
        ''
          # Set the system time from the hardware clock to work around a
          # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
          # to the *boot time* of the host).
          hwclock -s
        '';

      security.rngd.enable = false;
    })
    (mkIf ("${cfg.plan}" == "cx41") {

      fileSystems."/" =
        { device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };

      swapDevices = [ ];

      nix.gc_free_gb = 100;
      nix.maxJobs = lib.mkDefault 2;
      boot.loader.grub.enable = true;
      boot.loader.grub.version = 2;
      boot.loader.grub.device = "/dev/sda";
    })
  ];
}
