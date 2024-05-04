let
  sources = import ./nix/sources.nix;
  overlay = _: pkgs: { };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = { allowUnfree = true; };
  };

  morph = import sources.morph { };
  agenix-cli = (import sources.agenix-cli).default;
in
pkgs.mkShell {
  buildInputs = [
    agenix-cli
    morph

    pkgs.coreutils
    pkgs.jq
    pkgs.vault
    pkgs.niv
    pkgs.openssh_gssapi # the buildkite elastic stack supports gssapi or something
    pkgs.awscli
    pkgs.bashInteractive
    pkgs.git
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
