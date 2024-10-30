{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./nixops/modules/ofborg/module.nix
  ];

  system.stateVersion = 5;

  nixpkgs.overlays = [
    (final: prev: {
      # https://github.com/NixOS/nixpkgs/pull/198306
      prometheus-node-exporter = prev.prometheus-node-exporter.overrideAttrs (_: {
        patches = [ ];
      });
    })
  ];

  environment.systemPackages = [ config.nix.package ];

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = false;
  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  #services.activate-system.enable = true;
  services.ofborg.enable = true;
  services.ofborg.package = inputs.ofborg.packages.${pkgs.system}.ofborg.rs;

  services.ofborg.configFile =
    let
      unformatted = pkgs.writeText "ofborg.unformatted.json"
        (builtins.toJSON config.services.ofborg.config_merged);
      config_json = pkgs.runCommand "ofborg.json"
        { buildInputs = [ pkgs.jq ]; }
        ''
          cat ${unformatted} | jq '.' > $out
        '';
    in
      config_json;

  # Manage user for ofborg, this enables creating/deleting users
  # depending on what modules are enabled.
  users.knownGroups = [ "ofborg" ];
  users.knownUsers = [ "ofborg" ];

  services.nix-daemon.enable = true;

  nix.settings = {
    "extra-experimental-features" = [ "nix-command" "flakes" ];
  };

  nix.package = pkgs.nix;
  # bash doesn't export /run/current-system/sw/bin to $PATH,
  # which we need for nix-store
  users.users.root.shell = "/bin/zsh";
  nix.settings.max-jobs = 4;
  nix.settings.cores = 1;
  nix.gc.automatic = true;
  nix.gc.user = "root";
  nix.gc.interval = { Minute = 15; };
  nix.gc.options =
    let gbFree = 50;
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

  users.users.root.openssh.authorizedKeys.keys = (import ./ssh-keys.nix).infra-build;
}
