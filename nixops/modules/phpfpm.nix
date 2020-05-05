{ config, lib, pkgs, ... }:
let
  cfg = config.services.phpfpm;
in
{
  options = {
    services.phpfpm.enable_main = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable_main {
    services.phpfpm.pools.main = {
      user = "nginx";
      group = "nginx";
      settings = {
        "listen.owner" = "nginx";
        "listen.group" = "nginx";
        "listen.mode" = "0600";
        "user" = "nginx";
        "pm" = "dynamic";
        "pm.max_children" = 75;
        "pm.start_servers" = 10;
        "pm.min_spare_servers" = 5;
        "pm.max_spare_servers" = 20;
        "pm.max_requests" = 500;
        "catch_workers_output" = true;
      };
    };
  };
}
