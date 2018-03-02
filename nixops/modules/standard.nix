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
      config.allowUnfree = true;
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
        allowedTCPPorts = [ 22 ];
      };
    };

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
        dates = "8:44";

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
