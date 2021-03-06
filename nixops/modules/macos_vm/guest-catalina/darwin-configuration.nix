{ config, lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = [ config.nix.package ];

  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  #services.activate-system.enable = true;
  services.ofborg.enable = true;
  services.ofborg.package = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/ofborg/archive/released.tar.gz";
  }) { # inherit pkgs;
  }).ofborg.rs;

  services.ofborg.configFile = "/var/lib/ofborg/config.json";
  # Manage user for ofborg, this enables creating/deleting users
  # depending on what modules are enabled.
  users.knownGroups = [ "ofborg" ];
  users.knownUsers = [ "ofborg" ];

  services.nix-daemon.enable = true;

  nix.maxJobs = 4;
  nix.buildCores = 1;
  nix.gc.automatic = true;
  nix.gc.interval = { Minute = 15; };
  nix.gc.options = let gbFree = 50;
  in "--max-freed $((${
    toString gbFree
  } * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  # If we drop below 20GiB during builds, free 20GiB
  nix.extraOptions = ''
    min-free = ${toString (30 * 1024 * 1024 * 1024)}
    max-free = ${toString (50 * 1024 * 1024 * 1024)}
  '';

  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"
  '';

  launchd.daemons.prometheus-node-exporter = {
    script = ''
      exec ${pkgs.prometheus-node-exporter}/bin/node_exporter
    '';

    serviceConfig.KeepAlive = true;
    serviceConfig.StandardErrorPath = "/var/log/prometheus-node-exporter.log";
    serviceConfig.StandardOutPath = "/var/log/prometheus-node-exporter.log";
  };
}
