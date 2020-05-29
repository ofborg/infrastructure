{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.monitoring;
  rabbitcfg = config.services.ofborg.rabbitmq;

  add_port = port: hostname: "${hostname}:${toString port}";
in {
  options = {
    services.ofborg.monitoring = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.str;
      };

      alert_manager_receivers = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = {};
      };

      monitoring_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      administration_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      builder_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      evaluator_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      extra_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      virtualHosts."${cfg.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000/";
          proxyWebsockets = true;
        };
      };

    };

    services.grafana = {
      enable = true;
      auth.anonymous.enable = true;
    };


    services.prometheus = {
      enable = true;

      extraFlags = [ "--web.enable-admin-api" "--web.external-url=https://${config.services.ofborg.website.domain}/prometheus/" ];

      alertmanagers = [ {
        scheme = "http";
        static_configs = [ {
          targets = [ "127.0.0.1:9093" ];
        } ];
      } ];
      alertmanager = {
        enable = true;
        configuration = {
          global = {};
          route = {
            receiver = "default_receiver";
            group_by = ["cluster" "alertname"];
          };

          receivers = cfg.alert_manager_receivers;
        };
      };

      rules = [ (builtins.toJSON {
        groups  = [ {
          name = "alerts";
          rules = [
            {
              alert = "MissingOfBorgData";
              expr = "absent(ofborg_queue_builder_waiting) == 1";
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "StalledEvaluator";
              expr = "ofborg_queue_evaluator_waiting > 0 and ofborg_queue_evaluator_in_progress == 0";
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "BrokenEvaluator";
              expr = "(ofborg_queue_evaluator_waiting > 0 or ofborg_queue_evaluator_in_progress > 0) and changes(ofborg_task_evaluation_check_complete[1h]) == 0";
              for = "30m";
              labels.severity = "page";
            }
            {
              alert = "StalledBuilder";
              expr = "ofborg_queue_builder_waiting > 0 and ofborg_queue_builder_in_progress == 0";
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "FreeInodes4HrsAway";
              expr = ''predict_linear(node_filesystem_files_free{mountpoint="/", instance!="aarch64.nixos.community:9100"}[1h], 4 * 3600) <= 0'';
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "FreeSpace2HrsAway";
              expr = ''predict_linear(node_filesystem_free{mountpoint="/", instance!="aarch64.nixos.community:9100"}[1h], 2 * 3600) <= 0'';
              for = "5m";
              labels.severity = "page";
            }
          ]; } ]; }) ];

      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = cfg.monitoring_nodes;
            }
          ];
        }

        {
          job_name = "ofborg-workers";
          honor_labels = true;
          static_configs = [
            {
              targets = lib.unique
                (map (add_port 9898)
                  cfg.administration_nodes);

            }
          ];
        }

        {
          job_name = "ofborg-builder";
          honor_labels = true;
          static_configs = [
            {
              targets = lib.unique
                (map (add_port config.services.ofborg.builder.metricsPort)
                  cfg.builder_nodes);
            }
          ];
        }

        {
          job_name = "node";
          static_configs = [
            {
              targets = lib.unique
                (map (add_port 9100)
                  (cfg.monitoring_nodes
                    ++ cfg.builder_nodes
                    ++ cfg.evaluator_nodes
                    ++ cfg.extra_nodes
                    ++ cfg.administration_nodes));
            }
          ];
        }

        {
          job_name = "rabbitmq";
          static_configs = [
            {
              targets = [ "${rabbitcfg.domain}:9419" ];
            }
          ];
        }

        # TODO: remove?
        {
          job_name = "ofborg-queue";
          metrics_path = "/prometheus.php";
          scheme = "https";
          static_configs = [
            {
              targets = [ rabbitcfg.domain ];
            }
          ];
        }
      ];
    };
  };
}
