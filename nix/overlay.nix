self: super: {
  terraform-provider-nixos = self.callPackage ./terraform-provider-nixos.nix {};
}
