
mkdir -m 0755 /nix && chown foo /nix
adduser foo
su foo

curl https://nixos.org/nix/install | bash
. /home/foo/.nix-profile/etc/profile.d/nix.sh

nix-env -f https://github.com/nix-community/nixos-generators/archive/master.tar.gz -i

nixos-generate  -f kexec -c ./config.nix


then ./format.sh

then make a host id:

     head -c4 /dev/urandom | od -A none -t x4

then add this to /mnt/etc/nixos/configuration.nix:

     boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ]; # or "nodev" for efi only
     services.openssh.enable = true;
     users.users.root.openssh.authorizedKeys.keys = [
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUy2CGT6P3q2kApZEuyCHsuCruwdRzeWMdQe/WjdCak grahamc@Petunia"
     ];
     networking.hostId = "...th ehost id...";
