{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.roles.core;
in {
  options = {
    roles.core = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable rec {
    services.ofborg.administrative.enable = true;
    services.ofborg.rabbitmq.enable = true;
    services.ofborg.webhook.enable = true;
    services.ofborg.builder.enable = true;
  };
}
