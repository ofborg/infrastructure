{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.rabbitmq = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.str;
      };

      monitoring_domain = lib.mkOption {
        type = lib.types.str;
      };

      monitoring_username = lib.mkOption {
        type = lib.types.str;
      };

      monitoring_password = lib.mkOption {
        type = lib.types.str;
      };

      cluster_ips = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      # TODO: remove?
      virtualHosts."${cfg.monitoring_domain}" = pkgs.nginxVhostPHP
        (pkgs.mutate ./queue-monitor {
          user = cfg.monitoring_username;
          password = cfg.monitoring_password;
          domain = cfg.domain;
        })
        config.services.phpfpm.pools.main.socket;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 9419 ];

    systemd.services."prometheus-rabbitmq-exporter" = {
      after = [ "rabbitmq.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.prometheus-rabbitmq-exporter}/bin/rabbitmq_exporter";
        DynamicUser = "yes";
      };
      environment = {
        PUBLISH_PORT = "9419";
        RABBIT_URL = "https://${cfg.domain}";
        SKIPVERIFY = "true"; # yeah, sue me. the current version in nixpkgs
        # fails on https://github.com/kbudde/rabbitmq_exporter/issues/149
        # and while I'd like to upgrade it, it was a can of worms... and
        # this username and password isn't very interesting, anyway.

        RABBIT_CAPABILITIE = "bert,no_sort";
        RABBIT_EXPORTERS = "exchange,node,queue";
        RABBIT_USER = cfg.monitoring_username;
        RABBIT_PASSWORD = cfg.monitoring_password;
      };
    };
  };
}
