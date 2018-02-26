{ pkgs, lib, config, ... }:
let
  cfg = config.services.ofborg;
in {
  options = {
    services.ofborg = {
      commit_email = lib.mkOption {
        type = lib.types.string;
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

      config_merged = lib.mkOption {
        default = (lib.attrsets.recursiveUpdate
          (lib.attrsets.recursiveUpdate cfg.config_public cfg.config_static)
          cfg.config_private);
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
  ];
}
