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
  "ofborg-evaluator-0" = {
    deployment = {
      targetHost = "147.28.147.247";
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
      targetHost = "86.109.7.63";
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
      targetHost = "147.28.145.245";
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
      targetHost = "136.144.57.69";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-3.expr.nix
      ./machines/ofborg-evaluator-3.system.nix
    ];
  };
  "ofborg-evaluator-4" = {
    deployment = {
      targetHost = "147.28.129.189";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-4.expr.nix
      ./machines/ofborg-evaluator-4.system.nix
    ];
  };
  "ofborg-evaluator-5" = {
    deployment = {
      targetHost = "145.40.89.255";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-5.expr.nix
      ./machines/ofborg-evaluator-5.system.nix
    ];
  };
  "ofborg-evaluator-6" = {
    deployment = {
      targetHost = "147.75.50.137";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-6.expr.nix
      ./machines/ofborg-evaluator-6.system.nix
    ];
  };
  "ofborg-evaluator-7" = {
    deployment = {
      targetHost = "147.28.147.83";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/ofborg-evaluator-7.expr.nix
      ./machines/ofborg-evaluator-7.system.nix
    ];
  };
}
