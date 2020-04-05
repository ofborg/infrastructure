{ nodes, pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.monitoring;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = builtins.concatStringsSep "\n" (lib.mapAttrsToList
      (name: node:
        ''
          # ${name}
          ${if node.config.networking.publicIPv4 != null then ''
          iptables -A nixos-fw -p tcp \
            --dport 3100 --source ${node.config.networking.publicIPv4}/32 \
            --jump nixos-fw-accept
            '' else ''
              #     (null)
            ''}'') nodes);

    services.loki = {
      enable = true;
      configFile = ./logging/loki.yml;
    };
  };
}
