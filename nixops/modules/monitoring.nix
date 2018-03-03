{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.monitoring;
  rabbitcfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.monitoring = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.string;
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

      alertmanagerURL = [ "http://127.0.0.1:9093" ];
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
              targets = [ ];
            }
          ];
        }

        {
          job_name = "ofborg-workers";
          honor_labels = true;
          static_configs = [
            {
              targets = [ ];
            }
          ];
        }

        {
          job_name = "node";
          static_configs = [
            {
              targets = [ ];
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
