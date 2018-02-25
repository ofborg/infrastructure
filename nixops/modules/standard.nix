{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {};

  config = {
    nixpkgs.config.allowUnfree = true;

    services.openssh.enable = true;
    networking = {
      nameservers = [
        "4.2.2.1"
        "4.2.2.2"
        "2001:4860:4860::8888"
      ];
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };
    };

    users = {
      mutableUsers = false;
    };
  };
}
