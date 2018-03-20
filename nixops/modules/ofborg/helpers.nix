{ config, pkgs }:
{
  rustborgservice = bin: {
    enable = true;
    after = [ "network.target" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      nixUnstable
      git
      curl
      bash
    ];

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
      export RUST_BACKTRACE=1
      exec ${pkgs.ofborg}/bin/${bin} ${config.services.ofborg.config_json}
    '';
  };
}
