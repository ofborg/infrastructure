let
  pkgs = import ./nix;

  inherit (pkgs) stdenv;

in stdenv.mkDerivation rec {
  name = "gh-event-forwarder";
  buildInputs = with pkgs; [
    nix-prefetch-git
    git
    nixops
    (terraform_0_11.withPlugins (plugins: [
      terraform-provider-nixos
      plugins.packet
      plugins.local
    ]))
 ];

  HISTFILE = "${toString ./.}/.bash_hist";
  NIXOPS_DEPLOYMENT = "ofborg-production";
  NIX_PATH = "nixpkgs=${pkgs.path}";
}
