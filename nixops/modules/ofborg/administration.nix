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
    # For the stats service:
    networking.firewall.allowedTCPPorts = [ 9898 ];

    systemd = {
      services = {
        ofborg-github-comment-filter =
          helpers.rustborgservice "github_comment_filter";

        ofborg-github-comment-poster =
          helpers.rustborgservice "github_comment_poster";

        ofborg-evaluation-filter =
          helpers.rustborgservice "evaluation_filter";

        ofborg-stats =
          helpers.rustborgservice "stats";
      };
    };
  };
}
