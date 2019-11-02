#!/bin/sh

set -eux

format() {
  parted -s "$1" -- mklabel msdos

  parted -s "$1" -- mkpart primary 1MiB 512MiB
  parted -s "$1" -- set 1 boot on

  parted -s "$1" -- mkpart primary 512MiB 100%
  parted -s "$1" -- print
}

zpool destroy -f rpool || true
(
  mdadm -S /dev/md127
  mdadm /dev/md127 -r /dev/sda1
  mdadm /dev/md127 -r /dev/sdb1

  dd if=/dev/zero of=/dev/sda1 bs=1M count=1024
  dd if=/dev/zero of=/dev/sdb1 bs=1M count=1024
  rm /etc/mdadm/mdadm.conf
) || true
udevadm settle

format /dev/sda
format /dev/sdb

udevadm settle

zpool create \
  -o ashift=12 \
  -O acltype=posixacl \
  -O xattr=sa \
  -O atime=off \
  -O relatime=off \
  -O compression=lz4 \
  rpool mirror \
    /dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18471FAE1869-part2 \
    /dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18471FAE1989-part2

zfs create -o mountpoint=none rpool/safe
zfs create -o mountpoint=legacy rpool/safe/root
zfs create -o mountpoint=none rpool/local
zfs create -o mountpoint=legacy rpool/local/nix

mount -t zfs rpool/safe/root /mnt
mkdir -p /mnt/nix
mount -t zfs rpool/local/nix /mnt/nix

mdadm \
  --create /dev/md127 \
  --metadata 0.90 \
  --level=1 \
  --raid-devices=2 \
  /dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18471FAE1989-part1 \
  /dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18471FAE1869-part1 \
  --force

mkfs.ext4 -m 0 -L boot -j /dev/md127
mkdir /mnt/boot
mount /dev/md127 /mnt/boot

nixos-generate-config --root /mnt

