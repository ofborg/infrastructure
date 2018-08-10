{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {
    nix.gc_free_gb = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = {
    nixpkgs = {
      overlays = [ (import ../../nix/overlay.nix) ];
      config = {
        allowUnfree = true;
        packageOverrides = pkgs: {
        };
      };
    };

    services.openssh.enable = true;
    networking = {
      nameservers = [
        "4.2.2.1"
        "4.2.2.2"
        "2001:4860:4860::8888"
      ];
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 9100 ];
      };
    };

    services.prometheus.nodeExporter = {
      enable = true;
      enabledCollectors = [
        # "cpu" # broken?
        "bonding" "systemd" "diskstats" "filesystem" "netstat" "meminfo"
        "textfile"
      ];
      extraFlags = [
        "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
        ""
      ];
    };

    system.activationScripts.node-exporter-system-version = ''
      mkdir -pm 0775 /var/lib/prometheus-node-exporter-text-files
      (
        cd /var/lib/prometheus-node-exporter-text-files
        (
          echo -n "system_version ";
          readlink /nix/var/nix/profiles/system | cut -d- -f2
        ) > system-version.prom.next
        mv system-version.prom.next system-version.prom
      )

    '';

    users = {
      mutableUsers = false;
    };

    nix = {
      useSandbox = true;
      nixPath = [
        # Ruin the config so we don't accidentally run
        # nixos-rebuild switch on the host
        (let
          cfg = pkgs.writeText "configuration.nix"
            ''
              assert builtins.trace
                "Hey dummy, you're on your server! Use NixOps!"
                false;
              {}
            '';
         in "nixos-config=${cfg}")

         # Copy the channel version from the deploy host to the target
         "nixpkgs=/run/current-system/nixpkgs"
      ];

      gc = {
        automatic = true;
        dates = "*:0/15";

        options = ''
          --max-freed "$((${toString config.nix.gc_free_gb} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"
        '';
      };
    };
    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
  };
}
