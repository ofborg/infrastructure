{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {
    services.php-fpm.enable_main = lib.mkEnableOption {
    };
  };

  config = lib.mkIf cfg.enable {
    services.phpfpm.pools.main = {
      listen = "/run/php-fpm.sock";
      extraConfig = ''

        listen.owner = nginx
        listen.group = nginx
        listen.mode = 0600
        user = nginx
        pm = dynamic
        pm.max_children = 75
        pm.start_servers = 10
        pm.min_spare_servers = 5
        pm.max_spare_servers = 20
        pm.max_requests = 500
        catch_workers_output = yes
      '';
    };

  };
}
