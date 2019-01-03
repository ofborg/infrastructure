{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  helpers = import ./helpers.nix { inherit config pkgs; };
  cfg = config.services.ofborg.administrative;
in {
  config = mkIf cfg.enable rec {
    systemd = {
      timers = {
        prune-ofborg-logs = {
          description = "Prune OfBorg logs";
          wantedBy = [ "timers.target" ];
          partOf = [ "prune-ofborg-logs.service" ];
          enable = true;
          timerConfig = {
            OnCalendar = "*:0/25";
            Unit = "prune-ofborg-logs.service";
            Persistent = "yes";
            AccuracySec = "1m";
            RandomizedDelaySec = "30s";
          };
        };
      };

      services = {
        setup-ofborg-logdir = {
          enable = true;
          before = [ "ofborg-log-collector.service" ];
          wantedBy = [ "multi-user.target" "ofborg-log-collector.service" ];

          serviceConfig.Type = "oneshot";
          serviceConfig.RemainAfterExit = true;

          script = ''
            mkdir -m 0755 -p "${config.services.ofborg.config_merged.log_storage.path}"
            chown ofborg:ofborg "${config.services.ofborg.config_merged.log_storage.path}"
          '';
        };

        prune-ofborg-logs = {
          serviceConfig = {
            User = "ofborg";
            Group = "ofborg";
            Type = "oneshot";
            PrivateTmp = true;
            WorkingDirectory = config.services.ofborg.config_merged.log_storage.path;
          };

          script = ''
            find "${config.services.ofborg.config_merged.log_storage.path}" \
              -type f -mtime +7 -not -name '*.json' \
              -exec sh -c "echo '***DELETED LOGS***' > {}" \;
          '';
        };

        "ofborg-log-message-collector" =
          helpers.rustborgservice "log_message_collector";
      };
    };
  };
}
