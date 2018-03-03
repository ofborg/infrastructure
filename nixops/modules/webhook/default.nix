{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.webhook;
  rabbitcfg = config.services.ofborg.rabbitmq;

  configuredWebhook = pkgs.runCommand "configured-webhook"
    {
      src = pkgs.webhook_api;
      config = pkgs.mutate ./config.php {
        domain = rabbitcfg.domain;
        username = cfg.rabbit_username;
        password = cfg.rabbit_password;
        vhost = "ofborg";
        github_shared_secret = cfg.github_shared_secret;
      };
    }
    ''
      cp -r $src $out
      chmod -R u+w $out
      cp -r $config $out/config.php
    '';

in {
  options = {
    services.ofborg.webhook = {
      enable = lib.mkEnableOption {
      };

      # !!! Write a config.php using these options
      domain = lib.mkOption {
        type = lib.types.string;
      };

      rabbit_host = lib.mkOption {
        type = lib.types.string;
      };

      rabbit_username = lib.mkOption {
        type = lib.types.string;
      };

      rabbit_password = lib.mkOption {
        type = lib.types.string;
      };

      github_shared_secret = lib.mkOption {
        type = lib.types.string;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = pkgs.nginxVhostPHP
        "${configuredWebhook}/web";
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
