let
  pkgs = import ./nix;

  inherit (pkgs) stdenv;

in stdenv.mkDerivation rec {
  name = "gh-event-forwarder";
  buildInputs = with pkgs; [
    nix-prefetch-git
    git
    gitAndTools.git-crypt
    nixops
    morph
    (terraform_0_11.withPlugins (plugins: [
      terraform-provider-nixos
      plugins.packet
      plugins.local
      plugins.aws
      plugins.dns
      plugins.rabbitmq
    ]))
 ];

  HISTFILE = "${toString ./.}/.bash_hist";
  NIX_PATH = "nixpkgs=${pkgs.path}:ofborg-infra=${toString ./.}";
}
