{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.rabbitmq = {
      enable = lib.mkEnableOption {
      };

      monitoring_domain = lib.mkOption {
        type = lib.types.str;
        default = "events.ofborg.org";
      };

      monitoring_username = lib.mkOption {
        type = lib.types.str;
        default = "monitoring";
      };

      cluster_ips = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.monitoring_password_file = {
      file = ../../../secrets/core/monitoring/rabbitmq_monitoring_password;
      mode = "440";
      owner = "nginx";
      group = "keys";
    };

    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      # TODO: remove?
      virtualHosts."${cfg.monitoring_domain}" = pkgs.nginxVhostPHP
        (pkgs.mutate ./queue-monitor {
          user = cfg.monitoring_username;
          password_file = config.age.secrets.monitoring_password_file.path;
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
        SupplementaryGroups = [ "keys" ];
      };
      environment = {
        PUBLISH_PORT = "9419";
        RABBIT_URL = "https://${cfg.domain}";
        RABBIT_EXPORTERS = "exchange,node,queue";
        RABBIT_USER = cfg.monitoring_username;
        RABBIT_PASSWORD_FILE = config.age.secrets.monitoring_password_file.path;
      };
    };
  };
}
