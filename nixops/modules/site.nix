{ config, pkgs, ... }:
let
  readJSON = file: builtins.fromJSON
    (builtins.readFile file);
  cfg = config;
in {
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

    services.ofborg.website.domain = "nix.ci";

    services.ofborg.log-viewer.domain = "logs.nix.ci";
    services.ofborg.monitoring.domain = "monitoring.nix.ci";
    services.ofborg.monitoring.extra_nodes = [
      "aarch64.nixos.community"
    ];

    services.ofborg.webhook.domain = "webhook.nix.ci";
    services.ofborg.rabbitmq.domain = "devoted-teal-duck.rmq.cloudamqp.com";

    services.ofborg.config_public = readJSON ../../repos/ofborg/config.public.json;

    users.mutableUsers = false;
  };
}
