{
  description = "ofborg infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = { url = "github:LnL7/nix-darwin"; inputs.nixpkgs.follows = "nixpkgs"; };
    ofborg = { url = "github:NixOS/ofborg"; };
  };

  outputs =
    { nixpkgs
    , darwin
    , ...
    }@inputs:
    {
      darwinConfigurations =
        let
          mac = system: darwin.lib.darwinSystem {
            inherit system inputs;

            modules = [
              ./darwin-configuration.nix
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
          arm64 = mac "aarch64-darwin";
          x86_64 = mac "x86_64-darwin";
        };
    };
}
