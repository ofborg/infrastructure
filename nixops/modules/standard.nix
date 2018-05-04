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
          prometheus-node-exporter = pkgs.prometheus-node-exporter.overrideAttrs (x: {
            # Update from 17.09's 0.14.0 because it lacked CPU metric support
            src = pkgs.fetchFromGitHub {
              rev = "v0.15.0";
              owner = "prometheus";
              repo = "node_exporter";
              sha256 = "0v1m6m9fmlw66s9v50y2rfr5kbpb9mxbwpcab4cmgcjs1y7wcn49";
            };
          });
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

    # Ugh, delete this garbage!
    systemd.services.prometheus-node-exporter.script = lib.mkForce (let
        cfg = config.services.prometheus.nodeExporter;
      in ''
        exec ${pkgs.prometheus-node-exporter}/bin/node_exporter \
          ${lib.concatMapStringsSep " " (x: "--collector." + x) cfg.enabledCollectors} \
          --web.listen-address ${cfg.listenAddress}:${toString cfg.port} \
          ${lib.concatStringsSep " \\\n  " cfg.extraFlags}
      '');

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
