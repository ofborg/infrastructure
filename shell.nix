let
  sources = import ./nix/sources.nix;
  overlay = _: pkgs: { };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = { allowUnfree = true; };
  };

  morph = import sources.morph { };
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
        p.rabbitmq
        p.equinix
    ]))
  ];

  HISTFILE = "${toString ./.}/.bash_hist";
  NIX_PATH = "nixpkgs=${pkgs.path}:ofborg-infra=${toString ./.}";
}
