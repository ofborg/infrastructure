{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.secrets;
in {
  options = {
    secrets = {
    };
  };

  config = { };
}
