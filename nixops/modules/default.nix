{
  imports = [
    "${(import ../../nix/sources.nix).agenix}/modules/age.nix"

    ./site.nix
    ./standard.nix
    ./secrets.nix
    ./roles.nix
    ./terraform.nix
    ./hetzner.nix
    ./ofborg
    ./rabbitmq
    ./webhook
    ./phpfpm.nix
    ./monitoring.nix
    ./logging.nix
    ./log-viewer.nix
    ./website.nix
  ];
}
