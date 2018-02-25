{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoPackage rec {
  name = "terraform-provider-nixos-${version}";
  version = "0.0.1";

  goPackagePath = "github.com/tweag/terraform-provider-nixos";

  src = pkgs.fetchFromGitHub {
    owner = "grahamc";
    repo = "terraform-provider-nixos";
    rev = "292bdefded6874ff4447e221ca8bad972eb131ff"; # my-go-impl 2018-02-24
    sha256 = "0pyvji5b5l5n3b0p0mw1bdd9fhjq2hwndr2fnraf41kcmn9gi4iv";
  };
}
