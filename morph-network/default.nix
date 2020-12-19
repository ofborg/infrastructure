{
  network = {
    pkgs = import <nixpkgs> {};
    nixConfig = {
      builders = "";
      experimental-features = "nix-command";
    };
  };

  "core" = {
    deployment = {
      targetHost = "136.144.57.217";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/core.expr.nix
      ./machines/core.system.nix
    ];
  };
}
