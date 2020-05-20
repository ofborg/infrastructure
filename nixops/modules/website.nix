{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.website;
in {
  options = {
    services.ofborg.website = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        enableACME = true;
        forceSSL = true;
        root = ../../website;
        locations = {
          "/prometheus/".proxyPass = "http://127.0.0.1:9090/prometheus/";
        };
      };
    };
  };
}
