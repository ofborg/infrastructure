{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  helpers = import ./helpers.nix { inherit config pkgs; };
  cfg = config.services.ofborg.evaluator;
in {
  options = {
    services.ofborg = {
      evaluator = {
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
        ofborg-evaluator =
          helpers.rustborgservice "mass_rebuilder";
      };
    };
  };
}
