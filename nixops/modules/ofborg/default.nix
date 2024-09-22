{ pkgs, lib, config, ... }:
{
  imports = [
    ./module.nix
    ./user.nix
    ./administration.nix
    ./log-collector.nix
    ./builder.nix
    ./evaluator.nix
  ];

  config = {
    nix.package = pkgs.nixVersions.nix_2_18;
    system.stateVersion = "23.05";
  };
}
