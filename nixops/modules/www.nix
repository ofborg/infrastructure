{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.log-viewer;
  rabbitcfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.www = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.string;
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
        locations = {
          "/".alias = "/status";
          "/status".proxyPass = "http://127.0.0.1:9090/alerts";
          "/static".proxyPass = "http://127.0.0.1:9090/static";
        };
      };
    };
  };
}
