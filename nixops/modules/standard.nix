{ config, lib, pkgs, ... }:
let
  secrets = config.secrets;
in {
  options = {};

  config = {
    nixpkgs.config.allowUnfree = true;

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
    };
    system.extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';

  };
}
