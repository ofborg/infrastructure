provider "metal" {}

variable "project_id" {
  default = "86d5d066-b891-4608-af55-a481aa2c0094"
}

resource "metal_device" "ofborg-core" {
  project_id       = var.project_id
  hostname         = "ofborg-core"
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = "c3.small.x86"
  facilities       = ["dc13"]

  custom_data = jsonencode({
    cpr_storage = {
      disks = [
        {
          device = "/dev/sda"
          partitions = [
            {
              label = "BIOS"
              number = 1
              size = "8M"
            },
            {
              label = "BOOT"
              number = 2
              size = "512M"
            },
            {
              label = "ROOT"
              number = 3
              size = 0
            },
          ]
        },
        {
          device = "/dev/sdb"
          partitions = [
            {
              label = "SECONDBIOS"
              number = 1
              size = "8M"
            },
            {
              label = "SECONDBOOT"
              number = 2
              size = "512M"
            },
            {
              label = "SECONDROOT"
              number = 3
              size = 0
            },
          ]
        },
      ]

      filesystems = [
        {
          mount = {
            device = "/dev/sda2"
            format = "vfat"
            point = "/boot"
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
        "npool/nix" = { properties = { mountpoint = "legacy" } }
        "npool/home" = { properties = { mountpoint = "legacy" } }
        "npool/var" = { properties = { mountpoint = "legacy" } }
      }

      mounts = [
        {
          dataset = "npool/root"
          point = "/"
        },
        {
          dataset = "npool/nix"
          point = "/nix"
        },
        {
          dataset ="npool/home"
          point ="/home"
        },
        {
          dataset ="npool/var"
          point ="/var"
        }
      ]
    }
  })

  # ipxe_script_url     = "http://images.platformequinix.net/nixos/installer-pre2/x86/netboot.ipxe"
  ipxe_script_url     = "https://netboot.gsc.io/installer-pre2/x86/netboot.ipxe"
  always_pxe       = false
  tags                = concat(var.tags, ["core-0", "skip-hydra"])
}

