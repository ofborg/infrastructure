{ config, pkgs, lib, ... }:
let
  cfg = config.services.ofborg;

  readJSON = file: builtins.fromJSON
    (builtins.readFile file);
in {
  options = {
    services.ofborg = {
      commit_email = lib.mkOption {
        type = lib.types.str;
        default = "ofborg@example.com";
      };

      config_public = lib.mkOption {
        default = readJSON ../../../repos/ofborg/config.public.json;
      };

      config_static = lib.mkOption {
        default = {
          log_storage.path = "/var/log/ofborg";
          checkout.root = if pkgs.stdenv.isDarwin then "/private/var/lib/ofborg/checkout" else "/ofborg/checkout";
          github_app.app_id = 20500;

          rabbitmq = {
            host = cfg.rabbitmq.domain;
            ssl = true;
            username = "ofborgsrvc";
            virtualhost = "ofborg";
          };
        } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
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
    };

    services.ofborg.rabbitmq = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "devoted-teal-duck.rmq.cloudamqp.com";
      };
    };
  };

  config = {
    age.secrets.rabbitmq_ofborgsrvc_password_file = {
      file = ../../../secrets/all/rabbitmq_ofborgsrvc_password;
      mode = "400";
      owner = "ofborg";
      group = "ofborg";
    };
    age.secrets.github_token_file = {
      file = ../../../secrets/all/github_token;
      mode = "400";
      owner = "ofborg";
      group = "ofborg";
    };
    age.secrets.github_app_key_file = {
      file = ../../../secrets/all/github_app.key;
      mode = "400";
      owner = "ofborg";
      group = "ofborg";
    };

    services.ofborg.config_override = {
      rabbitmq.password_file = config.age.secrets.rabbitmq_ofborgsrvc_password_file.path;
      github.token_file = config.age.secrets.github_token_file.path;
      github_app.private_key = config.age.secrets.github_app_key_file.path;
    };
  };
}
