{ config, pkgs, ... }:
{
  options.internalPkgs = pkgs.lib.mkOption { };
  config = {
    internalPkgs = {
      ofborg = (import ../../repos/ofborg/default.nix).ofborg.rs;
      webhook_api = (import ../../repos/ofborg/default.nix).ofborg.php;
      logviewer = let
        src = import ../../repos/log-viewer/release.nix { inherit pkgs; };
      in pkgs.runCommand "logviewer-site-only" {} ''
        cp -r ${src}/website $out
      '';
      log_api = ../../repos/ofborg/log-api;
    };

    services.ofborg.website.domain = "ofborg.org";

    services.ofborg.log-viewer.domain = "logs.ofborg.org";
    services.ofborg.monitoring.domain = "monitoring.ofborg.org";
    services.ofborg.monitoring.extra_nodes = [
      "aarch64.nixos.community"
    ];

    services.ofborg.webhook.domain = "webhook.ofborg.org";

    users.mutableUsers = false;
  };
}
