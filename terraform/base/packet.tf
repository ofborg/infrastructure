resource "metal_device" "ofborg-core" {
  project_id       = var.project_id
  hostname         = "ofborg-core"
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = "c3.small.x86"
  facilities       = ["dc13"]

  user_data = var.user_data

  custom_data = jsonencode({
    cpr_storage = {
      disks = [
        {
          device = "/dev/sda"
          partitions = [
            {
              label  = "BIOS"
              number = 1
              size   = "8M"
            },
            {
              label  = "BOOT"
              number = 2
              size   = "512M"
            },
            {
              label  = "ROOT"
              number = 3
              size   = 0
            },
          ]
        },
        {
          device = "/dev/sdb"
          partitions = [
            {
              label  = "SECONDBIOS"
              number = 1
              size   = "8M"
            },
            {
              label  = "SECONDBOOT"
              number = 2
              size   = "512M"
            },
            {
              label  = "SECONDROOT"
              number = 3
              size   = 0
            },
          ]
        },
      ]

      filesystems = [
        {
          mount = {
            device = "/dev/sda2"
            format = "vfat"
            point  = "/boot"
            create = { options = [
              "32",
              "-n",
              "EFI"
            ] }
          }
        },
      ]
    }

    cpr_zfs = {
      pools = { npool = { vdevs = [
        {
          disk = [
            "/dev/sda3",
            "/dev/sdb3"
          ]
        },
      ] } }

      datasets = {
        "npool/root" = { properties = { mountpoint = "legacy" } }
        "npool/nix"  = { properties = { mountpoint = "legacy" } }
        "npool/home" = { properties = { mountpoint = "legacy" } }
        "npool/var"  = { properties = { mountpoint = "legacy" } }
      }

      mounts = [
        {
          dataset = "npool/root"
          point   = "/"
        },
        {
          dataset = "npool/nix"
          point   = "/nix"
        },
        {
          dataset = "npool/home"
          point   = "/home"
        },
        {
          dataset = "npool/var"
          point   = "/var"
        }
      ]
    }
  })

  # In the future, try:
  # http://images.platformequinix.net/nixos/installer-pre2/x86/netboot.ipxe
  # This URL was causing issues before, but should be identical to the netboot.gsc.io
  # URL on an ongoing basis.
  ipxe_script_url = "https://netboot.gsc.io/installer-pre2/x86/netboot.ipxe"
  always_pxe      = false
  tags            = concat(var.tags, ["core-0", "skip-hydra"])

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "metal_device" "evaluator" {
  count            = var.evaluators
  project_id       = var.project_id
  hostname         = "ofborg-evaluator-${count.index}"
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = "m3.large.x86"
  metro            = var.metro
  user_data        = var.user_data
  ipxe_script_url  = "http://01ad16e6.packethost.net:3030/dispatch/hydra/01ad16e6.packethost.net/nixos-install-equinix-metal/release/x86"
  always_pxe       = false
  tags             = concat(var.tags, ["evaluator", "skip-hydra"])

  lifecycle {
    ignore_changes = [user_data]
  }
}
