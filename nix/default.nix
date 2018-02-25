let
  hostpkgs = import <nixpkgs> {};

  srcDef = builtins.fromJSON (builtins.readFile ./nixpkgs.json);

  inherit (hostpkgs) fetchFromGitHub fetchpatch fetchurl;
in import (hostpkgs.stdenv.mkDerivation {
  name = "ofborg-nixpkgs-${builtins.substring 0 10 srcDef.rev}";
  phases = [ "unpackPhase" "patchPhase" "markRevision" "moveToOut" ];

  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    inherit (srcDef) rev sha256;
  };

  patches = [
  ];

  markRevision = ''
    echo "${srcDef.rev}" >> ./.rev
    echo "${srcDef.sha256}" >> ./.sha256
  '';

  moveToOut = ''
    root=$(pwd)
    cd ..
    mv "$root" $out
  '';
}) {
  overlays = [
    (import ./overlay.nix)
  ];
}
