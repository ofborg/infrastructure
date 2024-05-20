{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.webhook;
  rabbitcfg = config.services.ofborg.rabbitmq;
in
{
  options = {
    services.ofborg.webhook = {
      enable = lib.mkEnableOption { };

      # !!! Write a config.php using these options
      domain = lib.mkOption {
        type = lib.types.str;
      };

      rabbit_host = lib.mkOption {
        type = lib.types.str;
      };

      rabbit_username = lib.mkOption {
        type = lib.types.str;
        default = "webhook";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.rabbit_password_file = {
      file = ../../../secrets/core/webhook/rabbit_password;
      mode = "400";
      owner = "nginx";
    };
    age.secrets.github_shared_secret_file = {
      file = ../../../secrets/core/webhook/github_shared_secret;
      mode = "400";
      owner = "nginx";
    };

    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" =
        let
          configuredWebhook = pkgs.runCommand "configured-webhook"
            {
              src = config.internalPkgs.webhook_api;
              config = pkgs.mutate ./config.php {
                domain = rabbitcfg.domain;
                username = cfg.rabbit_username;
                password_file = config.age.secrets.rabbit_password_file.path;
                vhost = "ofborg";
                github_shared_secret_file = config.age.secrets.github_shared_secret_file.path;
              };
            }
            ''
              cp -r $src $out
              chmod -R u+w $out
              cp -r $config $out/config.php
            '';
        in
        pkgs.nginxVhostPHP
          "${configuredWebhook}/web"
          config.services.phpfpm.pools.main.socket;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
