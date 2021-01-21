{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {
    nix.gc_free_gb = lib.mkOption {
      type = lib.types.int;
      default = 20;
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
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUy2CGT6P3q2kApZEuyCHsuCruwdRzeWMdQe/WjdCak grahamc@Petunia"
      ''cert-authority,principals="root" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3fMouUnMVF/sHXiuhwiz0+91J24SA/bGvKGrdOEwM0r5EF0rA0NhJ6v2r8qSm+QgjaxHjbaYVyBtdc3G4mrC4UaDF30ttoB/z4HP8ilhIlv5pnd85yEq61qLILKy4xs8hIIB/Eg4dFuaBVyhz8HJk/QwAo8yfdVgus8jBuiFxi1Hx/Po6p4Ou8cM1wMrs96mCHsTr39pVkGszJWFK7LWXZ2M+rkPdHb80Ht+TI9OJnPVY6J7Q/9A55FNdfnhC5cHyfKOZnsEr7UupM5PVKMDLYWHw5JVAyZqDVwrfL+XeaIej2Er+dCS9aTkhPHXHJ898w5Mchugxe8cPOQ/smmF+kN1WTITmL838N/H7bnP0AQBpglEq4Gcu9SSX1tTtonhqUdNKg9JcTwo94sH5jdxqYNEJH2527D8E7kDa+7vLka5PKg5xwCGCsFbux1/TIyr1qm5TYWzfyNWFhNQbJ90276Gq/d59SjNGhHx6tblbL6p3Wi7g0Qwrg1LkAmtEf2hyRP1SZfOLvMxiqj1yq6o6bYf3v0QEXPKoq0md0gokZ9oGE3rPr622ey5KC7ZbbcisYxKKwPT9lE/7kJHzxH1kpdHNdP6MfF00jbIAZjf7E0qohjC4gPAN3iammlitt9xvHwd3XopA96g5YO+KkFXlFSpN4BsWfGUb17BcRkGtyQ==''

    ];
    networking = {
      nameservers = [
        "4.2.2.1"
        "4.2.2.2"
        "2001:4860:4860::8888"
      ];
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 9100 ];
        logRefusedConnections = false;
      };
    };

    systemd.services.promtail = {
      after = [ "loki.service" ];
      before = [ "syslog.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.grafana-loki}/bin/promtail -config.file ${./logging/promtail.yml}";
        # DynamicUser = "yes";
      };
    };

    services.prometheus.exporters.node = {
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
