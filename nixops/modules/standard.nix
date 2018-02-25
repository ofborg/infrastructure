{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {};

  config = {
    nixpkgs.config.allowUnfree = true;

    services.openssh.enable = true;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };

    users = {
      mutableUsers = false;
    };
  };
}
