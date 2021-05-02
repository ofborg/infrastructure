{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.services.ofborg.macos_vm;

  versions = {
    catalina = {
      zvolName = "rpool/catalina";
      guestConfigDir = pkgs.runCommand "guest-config-catalina" {
        buildInputs = [ pkgs.shellcheck ];
      } ''
        mkdir -p $out
        cp -r ${./guest-catalina}/* $out/
        cp ${config.services.ofborg.config_json} $out/ofborg-config.json
        chmod +x $out/*.sh
        shellcheck $out/*.sh
      '';
      cloverImage = (pkgs.callPackage ./dist/clover-catalina { }).clover-image;
    };
  };
in {
  imports = [ ./host ];

  options = {
    services.ofborg.macos_vm = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      version = mkOption { type = types.enum [ "catalina" ]; };
    };
  };

  config = mkIf cfg.enable (let oscfg = versions."${cfg.version}";
  in rec {
    services.ofborg.config_override = {
      checkout.root = "/private/var/lib/ofborg/checkout";
      nix.system = "x86_64-darwin";
    };
    macosGuest = {
      enable = true;

      network = {
        interiorNetworkPrefix = "10.172.170"; # 172="n", 170="x"
      };

      guest = {
        zvolName = oscfg.zvolName;
        guestConfigDir = oscfg.guestConfigDir;
        cloverImage = oscfg.cloverImage;
        ovmfCodeFile = ./dist/OVMF_CODE.fd;
        ovmfVarsFile = ./dist/OVMF_VARS-1024x768.fd;
      };
    };

    systemd.services.free-space = let
      disk = "/";
      minFree = 5 * 1024 * 1024; # 5 GB
      service = "run-macos-vm.service";
    in {
      startAt = "*:0/10";
      path = [ pkgs.coreutils ];
      serviceConfig = {
        ExecCondition = pkgs.writeShellScript "free-space-condition" ''
          [[ "$(df -k --output=avail ${disk} | tail -n 1)" -lt "${
            toString minFree
          }" ]] && exit 0
        '';
        ExecStart =
          "/run/current-system/systemd/bin/systemctl restart ${service}";
      };
    };
  });
}
