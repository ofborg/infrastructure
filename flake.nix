{
  description = "ofborg infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = { url = "github:LnL7/nix-darwin"; inputs.nixpkgs.follows = "nixpkgs"; };
    ofborg = { url = "github:NixOS/ofborg"; };
    agenix = { url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; inputs.darwin.follows = "darwin"; };
  };

  outputs =
    { nixpkgs
    , darwin
    , ofborg
    , agenix
    , ...
    }@inputs:
    {
      darwinConfigurations =
        let
          mac = system: ofborg_identity: darwin.lib.darwinSystem {
            inherit system inputs;

            modules = [
              ./darwin-configuration.nix
              {
                services.ofborg.config_public = builtins.fromJSON (builtins.readFile "${ofborg}/config.public.json");
                services.ofborg.config_override.runner.identity = ofborg_identity;
                services.ofborg.config_override.nix.system = if (system == "aarch64-darwin") then [
                  "aarch64-darwin"
                  "x86_64-darwin"
                ] else system;
              }
              agenix.darwinModules.default
            ]
            ++ nixpkgs.lib.optionals (system == "aarch64-darwin") [
              {
                launchd.daemons."ofborg-apfs-cleanup" = {
                  # For whatever reason, Rosetta keeps garbage around until we run this command
                  script = ''
                    /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -P -minsize 0 /System/Volumes/Data
                  '';

                  serviceConfig = {
                    StartCalendarInterval = [
                      {
                        Hour = 2;
                        Minute = 30;
                      }
                    ];
                    StandardErrorPath = "/var/log/apfs-cleanup.log";
                    StandardOutPath = "/var/log/apfs-cleanup.log";
                  };
                };
              }
            ];
          };
        in
        {
          # 208.83.1.173
          nixos-foundation-macstadium-44911305 = mac "x86_64-darwin" "macstadium-x86-44911305";
          # 208.83.1.175
          nixos-foundation-macstadium-44911362 = mac "x86_64-darwin" "macstadium-x86-44911362";
          # 208.83.1.186
          nixos-foundation-macstadium-44911507 = mac "x86_64-darwin" "macstadium-x86-44911507";

          # 208.83.1.145
          nixos-foundation-macstadium-44911207 = mac "aarch64-darwin" "macstadium-m1-44911207";
          # 208.83.1.181
          nixos-foundation-macstadium-44911104 = mac "aarch64-darwin" "macstadium-m1-44911104";
        };
    };
}
