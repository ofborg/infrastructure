{ config, pkgs }:
{
  rustborgservice = { bin, config_merged ? config.services.ofborg.config_merged }:
    let
      config_json =
        let
          unformatted = pkgs.writeText "ofborg.unformatted.json"
            (builtins.toJSON config_merged);
        in
        pkgs.runCommand "ofborg.json"
          { buildInputs = [ pkgs.jq ]; }
          ''
            cat ${unformatted} | jq '.' > $out
          '';
    in
    {
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
        export GIT_AUTHOR_EMAIL="${config.services.ofborg.commit_email}"
        export GIT_AUTHOR_NAME="OfBorg"
        exec ${config.internalPkgs.ofborg}/bin/${bin} ${config_json}
      '';
    };
}
