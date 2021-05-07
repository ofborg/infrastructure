{
  network = {
    pkgs =
      let
        sources = import ../nix/sources.nix;
      in
      import sources.nixpkgs {
        config = {
          allowUnfree = true;
        };
      };
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
  "macofborg1" = {
    deployment = {
      targetHost = "100.89.83.94";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/macofborg1.expr.nix
      ./machines/macofborg1.system.nix
    ];
  };
  "ofborg-evaluator-0" = {
    deployment = {
      targetHost = "147.75.67.153";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-0.expr.nix
      ./machines/ofborg-evaluator-0.system.nix
    ];
  };
  "ofborg-evaluator-1" = {
    deployment = {
      targetHost = "147.75.38.27";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-1.expr.nix
      ./machines/ofborg-evaluator-1.system.nix
    ];
  };
  "ofborg-evaluator-2" = {
    deployment = {
      targetHost = "147.75.39.221";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-2.expr.nix
      ./machines/ofborg-evaluator-2.system.nix
    ];
  };
  "ofborg-evaluator-3" = {
    deployment = {
      targetHost = "147.75.38.35";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-3.expr.nix
      ./machines/ofborg-evaluator-3.system.nix
    ];
  };
}
