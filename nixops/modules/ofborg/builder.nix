{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  helpers = import ./helpers.nix { inherit config pkgs; };
  cfg = config.services.ofborg.builder;
in {
  options = {
    services.ofborg = {
      builder = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };
  };

  config = mkIf cfg.enable rec {
    systemd = {
      services = {
        ofborg-builder =
          helpers.rustborgservice "builder";
      };
    };

    nix.package = pkgs.nixUnstable;
  };
}
