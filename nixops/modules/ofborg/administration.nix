{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  helpers = import ./helpers.nix { inherit config pkgs; };
  cfg = config.services.ofborg.administrative;
in {
  options = {
    services.ofborg = {
      administrative = {
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
        "ofborg-github-comment-filter" =
          helpers.rustborgservice "github_comment_filter";
      };
    };
  };
}
