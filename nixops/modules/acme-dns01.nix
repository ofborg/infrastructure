{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.acme-dns01;
in {
  options = {
    services.ofborg.acme-dns01 = {
      enable = lib.mkEnableOption {
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.string;
        default = [ ];
      };

      directory = lib.mkOption {
        default = "/var/lib/acme-dns01";
        type = lib.types.str;
        description = ''
          Directory where certs and other state will be stored by default.
        '';
      };

      environment = lib.mkOption {
        type = lib.types.str;
        description = "";
      };


      email = lib.mkOption {
        type = lib.types.str;
        description = "Contact email address for the CA to be able to reach you.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    deployment.keys.acme-dns01-env-file = {
      text = cfg.environment;
      user = "root";
      group = "root";
      permissions = "0600";
    };

    systemd.services.acme-dns01 = {
      enable = true;
      after = [ "network.target" "network-online.target" "acme-dns01-env-file-key.service" ];
      wants = [ "network-online.target" "acme-dns01-env-file-key.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        lego
      ];

      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
        EnvironmentFile = "/run/keys/acme-dns01-env-file";
      };

      preStart = ''
        mkdir -p '${cfg.directory}'
        chown 'root:root' '${cfg.directory}'
        chmod 755 '${cfg.directory}'
      '';

      script = let
        cmdline = [
          "--accept-tos"
          "--path" cfg.directory
          "--dns" "route53"
          "--email" cfg.email
        ] ++
          (lib.flatten
            (builtins.map
              (domain: ["--domains" domain]) cfg.domains)) ++ [
        ];
      in ''
        cd "${cfg.directory}";
        lego ${lib.escapeShellArgs cmdline} run
      '';
    };
  };
}
