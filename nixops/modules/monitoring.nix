{ nodes, pkgs, config, lib, ... }:
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
    age.secrets.pushover_app_token = {
      file = ../../secrets/core/monitoring/pushover/app_token;
      mode = "400";
      owner = "prometheus";
    };
    age.secrets.cole-h_key = {
      file = ../../secrets/core/monitoring/pushover/cole-h;
      mode = "400";
      owner = "prometheus";
    };

    services.ofborg.monitoring = let
        targethostIf = f: nodes:
          map (node: node.config.deployment.targetHost)
              (lib.filter f (lib.attrValues nodes));
      in {
        monitoring_nodes = targethostIf
          (node: node.config.services.ofborg.monitoring.enable)
          nodes;
        builder_nodes = targethostIf
          (node: node.config.services.ofborg.builder.enable)
          nodes;
        evaluator_nodes = targethostIf
          (node: node.config.services.ofborg.evaluator.enable)
          nodes;
        administration_nodes = targethostIf
          (node: node.config.services.ofborg.administrative.enable)
          nodes;
        extra_nodes = [
          "208.83.1.186" # x86_64-darwin from macstadium
          "208.83.1.175" # x86_64-darwin from macstadium
          "208.83.1.173" # x86_64-darwin from macstadium
          "208.83.1.145" # aarch64-darwin from macstadium
          "208.83.1.181" # aarch64-darwin from macstadium
        ];
      };


    services.nginx = {
      enable = true;
      recommendedProxySettings = true;

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
      settings."auth.anonymous".enabled = true;
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

          receivers = [
            {
              name = "default_receiver";
              pushover_configs = [
                {
                  # cole-h
                  user_key_file = config.age.secrets.cole-h_key.path;
                  token_file = config.age.secrets.pushover_app_token.path;
                }
              ];
            }
          ];
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
              expr = ''ofborg_queue_builder_waiting{arch!~".*-lowprior"} > 0 and ofborg_queue_builder_in_progress{arch!~".*-lowprior"} == 0'';
              # expr = "ofborg_queue_builder_waiting > 0 and ofborg_queue_builder_in_progress == 0";
              for = "30m";
              labels.severity = "page";
            }
            {
              alert = "FreeInodes4HrsAway";
              expr = ''predict_linear(node_filesystem_files_free{mountpoint="/", fsType="ext4", instance!="aarch64.nixos.community:9100"}[1h], 4 * 3600) <= 0'';
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "FreeInodesUrgent";
              # Less than 10% inodes available
              # TODO: We can probably get rid of this if we can find some way to get a working
              # chroot store on the new, big /ofborg disk... But when I tried, I ran into issues
              # like the per-user profiles thing having wrong permissions (even though they were
              # right)... Maybe caused by the older Nix they're running... x)
              # TODO: update nixpkgs (or at least somehow get a newer Nix), patch ofborg to try to
              # do the whole thing but never actually report prorgess (specifically eval errors) if
              # stuff breaks
              expr = ''(node_filesystem_files_free{mountpoint="/",fstype="ext4"} / node_filesystem_files{mountpoint="/",fstype="ext4"} * 100) < 10'';
              for = "1m";
              labels.severity = "page";
            }
            {
              alert = "FreeSpace2HrsAway";
              expr = ''predict_linear(node_filesystem_avail_bytes{mountpoint="/", instance!="aarch64.nixos.community:9100"}[1h], 2 * 3600) <= 0'';
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "TooManyPendingEvals";
              expr = ''ofborg_queue_evaluator_waiting > 50'';
              for = "5m";
              labels.severity = "page";
            }
            {
              alert = "TooManyPendingX86Builds";
              expr = ''ofborg_queue_builder_waiting{arch="x86_64-linux"} > 50'';
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
              targets = lib.unique
                (map (add_port 9419)
                  cfg.administration_nodes);

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
              targets = [ rabbitcfg.monitoring_domain ];
            }
          ];
        }
      ];
    };
  };
}
