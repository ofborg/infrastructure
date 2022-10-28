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
            ];
          };
        in
        {
          arm64 = mac "aarch64-darwin";
          x86_64 = mac "x86_64-darwin";
        };
    };
}
