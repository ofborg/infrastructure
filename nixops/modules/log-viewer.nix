{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.log-viewer;
  rabbitcfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.log-viewer = {
      enable = lib.mkEnableOption {
      };

      domain = lib.mkOption {
        type = lib.types.string;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        root = "${pkgs.logviewer}";
        enableACME = true;
        forceSSL = true;

        locations = {
          "/logfile" = {
            alias = config.services.ofborg.config_merged.log_storage.path;
            extraConfig = ''
              add_header Access-Control-Allow-Origin "*";
              add_header Access-Control-Request-Method "GET";
              add_header Content-Security-Policy "default-src 'none'; sandbox;";
              add_header Content-Type "text/plain; charset=utf-8";
              add_header X-Content-Type-Options "nosniff";
              add_header X-Frame-Options "deny";
              add_header X-XSS-Protection "1; mode=block";
            '';
          };

          "/logs" = {
            alias = pkgs.log_api;
            extraConfig = ''
              add_header Access-Control-Allow-Origin "*";
              add_header Access-Control-Request-Method "GET";
              add_header Content-Security-Policy "default-src 'none'; sandbox;";
              add_header X-Content-Type-Options "nosniff";
              add_header X-XSS-Protection "1; mode=block";

              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:/run/php-fpm.sock;
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME ${pkgs.log_api}/index.php;
              include ${pkgs.nginx}/conf/fastcgi_params;
              try_files /index.php =404;
            '';
          };
        };
      };
    };
  };
}
