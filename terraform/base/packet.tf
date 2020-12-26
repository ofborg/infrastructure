provider "metal" {}

output "deploy_targets" {
  value = merge(
      {
        core = {
          ip = metal_device.ofborg-core.network.0.address
          expression = "{ roles.core.enable = true; }"
        },
      },
      {for e in metal_device.evaluator : e.hostname => {
        ip = e.network.0.address
        expression = "{ services.ofborg = { builder.enable = true; evaluator.enable = true; }; }"
      }},
  )
}

variable "evaluators" {
  default = 5
}

variable "project_id" {
  default = "86d5d066-b891-4608-af55-a481aa2c0094"
}

variable "bootstrap_expr" {
  default = <<EXPR
{
  users.users.root.openssh.authorizedKeys.keys = [
    ''cert-authority,principals="root" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3fMouUnMVF/sHXiuhwiz0+91J24SA/bGvKGrdOEwM0r5EF0rA0NhJ6v2r8qSm+QgjaxHjbaYVyBtdc3G4mrC4UaDF30ttoB/z4HP8ilhIlv5pnd85yEq61qLILKy4xs8hIIB/Eg4dFuaBVyhz8HJk/QwAo8yfdVgus8jBuiFxi1Hx/Po6p4Ou8cM1wMrs96mCHsTr39pVkGszJWFK7LWXZ2M+rkPdHb80Ht+TI9OJnPVY6J7Q/9A55FNdfnhC5cHyfKOZnsEr7UupM5PVKMDLYWHw5JVAyZqDVwrfL+XeaIej2Er+dCS9aTkhPHXHJ898w5Mchugxe8cPOQ/smmF+kN1WTITmL838N/H7bnP0AQBpglEq4Gcu9SSX1tTtonhqUdNKg9JcTwo94sH5jdxqYNEJH2527D8E7kDa+7vLka5PKg5xwCGCsFbux1/TIyr1qm5TYWzfyNWFhNQbJ90276Gq/d59SjNGhHx6tblbL6p3Wi7g0Qwrg1LkAmtEf2hyRP1SZfOLvMxiqj1yq6o6bYf3v0QEXPKoq0md0gokZ9oGE3rPr622ey5KC7ZbbcisYxKKwPT9lE/7kJHzxH1kpdHNdP6MfF00jbIAZjf7E0qohjC4gPAN3iammlitt9xvHwd3XopA96g5YO+KkFXlFSpN4BsWfGUb17BcRkGtyQ==''
   ];
}
EXPR
}

resource "metal_device" "ofborg-core" {
  project_id       = var.project_id
  hostname         = "ofborg-core"
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = "c3.small.x86"
  facilities       = ["dc13"]

  user_data = <<USERDATA
#!nix
${var.bootstrap_expr}
USERDATA

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

  lifecycle {
    ignore_changes = [ user_data ]
  }
}

resource "metal_device" "evaluator" {
  count            = var.evaluators
  project_id       = var.project_id
  hostname         = "ofborg-evaluator-${count.index}"
  billing_cycle    = "hourly"
  operating_system = "custom_ipxe"
  plan             = "m1.xlarge.x86"
  facilities       = ["ewr1"]

  user_data = <<USERDATA
#!nix
${var.bootstrap_expr}
USERDATA

#  custom_data = jsonencode({
#    cpr_storage = {
#      disks = [
#        {
#          device = "/dev/disk/by-packet-category/boot1"
#          partitions = [
#            {
#              label = "BIOS"
#              number = 1
#              size = "8M"
#            },
#            {
#              label = "BOOT"
#              number = 2
#              size = "512M"
#            },
#            {
#              label = "ROOT"
#              number = 3
#              size = 0
#            },
#          ]
#        },
#      ]
#
#      filesystems = [
#        {
#          mount = {
#            device = "/dev/disk/by-packet-category/boot1-part2"
#            format = "vfat"
#            point = "/boot"
#            create = { options = [
#              "32",
#              "-n",
#              "EFI"
#            ] }
#          }
#        },
#      ]
#    }
#
#    cpr_zfs = {
#      pools = { npool = { vdevs = [
#        {
#          disk = [
#            "/dev/disk/by-packet-category/boot1-part3",
#            "/dev/disk/by-packet-category/storage1",
#            "/dev/disk/by-packet-category/storage2",
#            "/dev/disk/by-packet-category/storage3",
#            "/dev/disk/by-packet-category/storage4",
#            "/dev/disk/by-packet-category/storage5",
#            "/dev/disk/by-packet-category/storage6",
#          ]
#        },
#      ] } }
#
#      datasets = {
#        "npool/root" = { properties = { mountpoint = "legacy" } }
#        "npool/nix" = { properties = { mountpoint = "legacy" } }
#        "npool/home" = { properties = { mountpoint = "legacy" } }
#        "npool/var" = { properties = { mountpoint = "legacy" } }
#      }
#
#      mounts = [
#        {
#          dataset = "npool/root"
#          point = "/"
#        },
#        {
#          dataset = "npool/nix"
#          point = "/nix"
#        },
#        {
#          dataset ="npool/home"
#          point ="/home"
#        },
#        {
#          dataset ="npool/var"
#          point ="/var"
#        }
#      ]
#    }
#  })

  # ipxe_script_url     = "http://images.platformequinix.net/nixos/installer-pre2/x86/netboot.ipxe"
  ipxe_script_url     = "https://netboot.gsc.io/installer-pre2/x86/netboot.ipxe"
  always_pxe       = false
  tags                = concat(var.tags, ["evaluator", "skip-hydra"])

  lifecycle {
    ignore_changes = [ user_data ]
  }
}

