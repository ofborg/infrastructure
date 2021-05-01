{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.roles;
in {
  options = {
    roles.core = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

    roles.builder = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

    roles.darwin-builder = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

    roles.evaluator = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };

  };

  config = mkMerge [
    (mkIf cfg.core.enable rec {
      services.ofborg.administrative.enable = true;
      services.ofborg.rabbitmq.enable = true;
      services.ofborg.webhook.enable = true;
      services.ofborg.monitoring.enable = true;
      services.ofborg.log-viewer.enable = true;
      services.ofborg.website.enable = true;
    })
    (mkIf cfg.builder.enable rec {
      services.ofborg.builder.enable = true;
    })
    (mkIf cfg.darwin-builder.enable rec {
      services.ofborg.macos_vm.enable = true;
    })
    (mkIf cfg.evaluator.enable rec {
      services.ofborg.evaluator.enable = true;
      services.ofborg.config_override = {
        nix.initial_heap_size = "10g";
      };
    })
  ];
}
