{ config, pkgs }:
let
  nixCustom = pkgs.nix.overrideDerivation (drv: {
    patches = [
      (pkgs.fetchpatch {
        name = "nixpkgs-disallow-sri.patch";
        url = "https://github.com/LnL7/nix/commit/48888b1ff2d3b8f5f106f06e8c20c10f9c942a53.patch";
        sha256 = "03ncp2mrsp2nbdyfc0jr9gf76mf3vw425x0vwq8r4fsgjgd2c3li";
      })
    ];
    # The tests check SRI hashes, which won't pass anymore.
    doInstallCheck = false;
  });
in
{
  rustborgservice = bin: {
    enable = true;
    after = [ "network.target" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      nixCustom
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
      exec ${pkgs.ofborg}/bin/${bin} ${config.services.ofborg.config_json}
    '';
  };
}
