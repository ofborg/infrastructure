{ config, pkgs }:
{
  rustborgservice = bin: {
    enable = true;
    after = [ "network.target" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      nix
      git
      curl
      bash
    ];

    environment.RUST_BACKTRACE = "1";
    environment.RUST_LOG = "debug,async_std=error";
    environment.RUST_LOG_JSON = "1";

    serviceConfig = {
      User = "ofborg";
      Group = "ofborg";
      PrivateTmp = true;
      WorkingDirectory = config.users.users.ofborg.home;
      Restart = "always";
      RestartSec = "10s";
    };

    script = ''
      export HOME=${config.users.users.ofborg.home};
      export NIX_REMOTE=daemon;
      export NIX_PATH=nixpkgs=/run/current-system/nixpkgs;
      git config --global user.email "${config.services.ofborg.commit_email}"
      git config --global user.name "OfBorg"
      exec ${config.internalPkgs.ofborg}/bin/${bin} ${config.services.ofborg.config_json}
    '';
  };
}
