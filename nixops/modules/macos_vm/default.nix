{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.services.ofborg.macos_vm;

  versions = {
    catalina = {
      zvolName = "rpool/catalina";
      guestConfigDir = ./guest-catalina;
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
  });
}
