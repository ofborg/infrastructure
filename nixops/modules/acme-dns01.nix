{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.acme-dns01;
  foldListToAttrs = l: f:
    lib.foldl
      (coll: elem:
        let r = f elem;
        in coll // { "${r.name}" = r.value; }
      ) {} l;
in {
  options = {
    services.ofborg.acme-dns01 = {
      enable = lib.mkEnableOption {
      };

      domains = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            group = lib.mkOption {
              type = lib.types.str;
              default = "root";
            };

            bundle = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };

            block = lib.mkOption {
              type = lib.types.listOf lib.types.string;
              default = [];
            };

            postRenew = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
          };
        });
        default = {};
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

    systemd.targets.acme-certificates = {};
    systemd.timers = lib.flip lib.mapAttrs' cfg.domains (domain: attrs:
     { name = "acme-dns01-${domain}";
      value = {
        description = "Renew ACME Certificates";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Unit = "acme-dns01-${domain}.service";
          Persistent = "yes";
          AccuracySec = "5m";
          RandomizedDelaySec = "1h";
        };
      };
    });

    systemd.services = (lib.flip lib.mapAttrs' cfg.domains (domain: attrs:
      { name = "acme-dns01-${domain}";
        value = {
          enable = true;
          after = [ "network.target" "network-online.target" "acme-dns01-env-file-key.service" ];
          wants = [ "network-online.target" "acme-dns01-env-file-key.service" ];
          before = attrs.block ++ [ "acme-certificates.target" ];
          wantedBy = [ "acme-certificates.target" ];
          requiredBy = attrs.block;

          path = with pkgs; [ lego ];

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
              "--domains" domain
            ];
            subopts = lib.optional (!attrs.bundle) "--no-bundle";
          in ''
            cd "${cfg.directory}";
            if [ -f "./certificates/${domain}.crt" ] && [ -f "./certificates/${domain}.crt" ]; then
              preHash=$(md5sum "./certificates/${domain}.crt")
              ${pkgs.lego}/bin/lego ${lib.escapeShellArgs cmdline} renew  ${lib.escapeShellArgs subopts} --days 10
              postHash=$(md5sum "./certificates/${domain}.crt")
              if [ "$preHash" != "$postHash" ]; then
                echo "Certificate updated, running post-renew hooks"
                ${attrs.postRenew}
              fi
            else
              ${pkgs.lego}/bin/lego ${lib.escapeShellArgs cmdline} run ${lib.escapeShellArgs subopts} 
            fi

            chgrp "${attrs.group}" "./certificates/${domain}."*
            chmod g+r "./certificates/${domain}."*
            chmod o+x "./certificates/"
          '';
        };
      })
    );
  };
}
