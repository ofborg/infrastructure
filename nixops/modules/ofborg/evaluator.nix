{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  helpers = import ./helpers.nix { inherit config pkgs; };
  cfg = config.services.ofborg.evaluator;
in
{
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
    nix.nrBuildUsers = 128;

    systemd = {
      services = {
        ofborg-evaluator =
          helpers.rustborgservice { bin = "mass_rebuilder"; };
        ofborg-evaluator-2 =
          helpers.rustborgservice {
            bin = "mass_rebuilder";
            config_merged = lib.attrsets.recursiveUpdate config.services.ofborg.config_merged { runner.instance = 2; };
          };
        ofborg-evaluator-3 =
          helpers.rustborgservice {
            bin = "mass_rebuilder";
            config_merged = lib.attrsets.recursiveUpdate config.services.ofborg.config_merged { runner.instance = 3; };
          };
      };
    };
  };
}
