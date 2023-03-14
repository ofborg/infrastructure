{ pkgs, lib, config, ... }:
let
  cfg = config.services.ofborg;
in {
  options = {
    services.ofborg = {
      commit_email = lib.mkOption {
        type = lib.types.str;
        default = "ofborg@example.com";
      };

      config_public = lib.mkOption {
        default = {};
      };

      config_static = lib.mkOption {
        default = {
          log_storage.path = "/var/log/ofborg";
          checkout.root = "/var/lib/ofborg/checkout";
          runner.identity = "${config.networking.hostName}";
        };
      };

      config_private = lib.mkOption {
        default = {};
      };

      config_override = lib.mkOption {
        default = {};
      };

      config_merged = lib.mkOption {
        default = let
          stage1 = lib.attrsets.recursiveUpdate cfg.config_public cfg.config_static;
          stage2 = lib.attrsets.recursiveUpdate stage1 cfg.config_private;
          stage3 = lib.attrsets.recursiveUpdate stage2 cfg.config_override;
        in stage3;
      };

      config_json = lib.mkOption {
        default = let
            unformatted = pkgs.writeText "ofborg.unformatted.json"
              (builtins.toJSON config.services.ofborg.config_merged);
          in pkgs.runCommand "ofborg.json"
            { buildInputs = [ pkgs.jq ]; }
            ''
              cat ${unformatted} | jq '.' > $out
            '';
      };
    };
  };

  imports = [
    ./user.nix
    ./administration.nix
    ./log-collector.nix
    ./builder.nix
    ./evaluator.nix
  ];

  config.nix.package = pkgs.nixVersions.nix_2_13;
  config.system.stateVersion = "23.05";
}
