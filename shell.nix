let
  sources = import ./nix/sources.nix;
  overlay = _: pkgs: { };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = { allowUnfree = true; };
  };

  morph = import
    (pkgs.fetchFromGitHub {
      owner = "DBCDK";
      repo = "morph";
      rev = "081a5752825d4884d82b5b3b84baa426fadc2307";
      sha256 = "lZIZlwRTv1skWuwGBLXF4gyyaXF5IXjC36savQOh2JI=";
    })
    { };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.coreutils
    pkgs.jq
    pkgs.vault
    pkgs.niv
    pkgs.openssh
    pkgs.awscli
    pkgs.bashInteractive
    pkgs.git
    morph
    pkgs.shellcheck
    (pkgs.terraform_1.withPlugins (p: [
        p.cloudamqp
        p.metal
        p.rabbitmq
    ]))
  ];

  HISTFILE = "${toString ./.}/.bash_hist";
  NIX_PATH = "nixpkgs=${pkgs.path}:ofborg-infra=${toString ./.}";
}
