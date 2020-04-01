{ config, pkgs, ... }:
let
  readJSON = file: builtins.fromJSON
    (builtins.readFile file);
  cfg = config;
in {
  config = {
    nixpkgs.config.packageOverrides = {
      ofborg = (import ../../repos/ofborg/default.nix {}).ofborg.rs;
      webhook_api = (import ../../repos/ofborg/default.nix {}).ofborg.php;
      logviewer = let
        src = import ../../repos/log-viewer/release.nix { inherit pkgs; };
      in pkgs.runCommand "logviewer-site-only" {} ''
        cp -r ${src}/website $out
      '';
      log_api = ../../repos/ofborg/log-api;
    };

    services.ofborg.website.domain = "nix.ci";

    services.ofborg.log-viewer.domain = "logs.nix.ci";
    services.ofborg.monitoring.domain = "monitoring.nix.ci";
    services.ofborg.monitoring.extra_nodes = [
      "aarch64.nixos.community"
    ];

    services.ofborg.webhook.domain = "webhook.nix.ci";
    services.ofborg.rabbitmq.domain = "events.nix.ci";

    services.ofborg.config_public = readJSON ../../repos/ofborg/config.public.json;

    services.ofborg.config_private = {
      runner.known_users = let
          nixpkgsContributors =
            (readJSON ../../repos/ofborg/config.known-users.json).runner.known_users;
          extra = readJSON ../../repos/ofborg/config.extra-known-users.json;
        in nixpkgsContributors ++ extra;

      rabbitmq.host = cfg.services.ofborg.rabbitmq.domain;
    };

    users.mutableUsers = false;
  };
}
