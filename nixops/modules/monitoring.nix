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
        type = lib.types.string;
      };

      alert_manager_receivers = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = {};
      };

      monitoring_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.string;
      };

      administration_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.string;
      };

      builder_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.string;
      };

      evaluator_nodes = lib.mkOption {
        type = lib.types.listOf lib.types.string;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = pkgs.nginxVhostProxy
        "http://127.0.0.1:3000/";
    };

    services.grafana = {
      enable = true;
      auth.anonymous.enable = true;
    };


    services.prometheus = {
      enable = true;

      extraFlags = [ "--web.external-url=https://${config.services.ofborg.website.domain}/prometheus/" ];

      alertmanagerURL = [ "http://127.0.0.1:9093" ];
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

      rules = [
        ''
          ALERT MissingOfBorgData
          IF absent(ofborg_queue_builder_waiting) == 1
          FOR 5m
          LABELS {
            severity="page"
          }

          ALERT StalledEvaluator
          IF ofborg_queue_evaluator_waiting > 0 and ofborg_queue_evaluator_in_progress == 0
          FOR 5m
          LABELS {
            severity="page"
          }

          ALERT BrokenEvaluator
          IF (ofborg_queue_evaluator_waiting > 0 or ofborg_queue_evaluator_in_progress > 0) and changes(ofborg_task_evaluation_check_complete[1h]) == 0
          FOR 30m
          LABELS {
            severity="page"
          }

          ALERT StalledBuilder
          IF ofborg_queue_builder_waiting > 0 and ofborg_queue_builder_in_progress == 0
          FOR 5m
          LABELS {
            severity="page"
          }

          ALERT FreeInodes4HrsAway
          IF predict_linear(node_filesystem_files_free{mountpoint="/"}[1h], 4   * 3600) <= 0
          FOR 5m
          LABELS {
            severity="page"
          }

          ALERT FreeSpace4HrsAway
          IF predict_linear(node_filesystem_free{mountpoint="/"}[1h], 4 * 3600) <= 0
          FOR 5m
          LABELS {
            severity="page"
          }

        ''
      ];

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
          job_name = "node";
          static_configs = [
            {
              targets = lib.unique
                (map (add_port 9100)
                  (cfg.monitoring_nodes
                    ++ cfg.builder_nodes
                    ++ cfg.evaluator_nodes
                    ++ cfg.administration_nodes));
            }
          ];
        }

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
