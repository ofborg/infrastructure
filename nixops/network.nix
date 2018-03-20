# /network.nix
assert
  let
    identity = pkgs: let
      rev = builtins.readFile "${pkgs.path}/.rev";
      sha256 = builtins.readFile "${pkgs.path}/.sha256";
    in "${rev}  ${sha256}";

    actual = identity (import <nixpkgs> {});
    expected = identity (import ./../nix);

    diffTrace = act: exp:
      if exp == act then true
      else builtins.trace
        "
The pinned Nixpkgs has changed, but NixOps is still using the old one.

  Expected: ${exp}
  Actual: ${act}

Please exit and re-open the nix-shell
" false;
  in diffTrace actual expected;
{
  defaults = { nodes, lib, ... }: {
    imports = import ./modules;

    services.ofborg.monitoring = let
        hostnameIf = f: nodes:
          map (node: node.config.networking.hostName)
              (lib.filter f (lib.attrValues nodes));
      in {
        monitoring_nodes = hostnameIf
          (node: node.config.services.ofborg.monitoring.enable)
          nodes;
        builder_nodes = hostnameIf
          (node: node.config.services.ofborg.builder.enable)
          nodes;
        evaluator_nodes = hostnameIf
          (node: node.config.services.ofborg.evaluator.enable)
          nodes;
        administration_nodes = hostnameIf
          (node: node.config.services.ofborg.administrative.enable)
          nodes;
      };
  };
} // (
  let
    root = ./../terraform/nixops-generated;

    absRoot = builtins.toString root;

    filesAndType = builtins.readDir root;

    endsWith = suffix: string:
      let
        suffixLen = builtins.stringLength suffix;
        stringLen = builtins.stringLength string;

        presentSuffix = builtins.substring
          (stringLen - suffixLen)
          suffixLen
          string;
      in presentSuffix == suffix;

    withoutSuffix = suffix: string:
      let
        suffixLen = builtins.stringLength suffix;
        stringLen = builtins.stringLength string;

        presentSuffix = builtins.substring
          (stringLen - suffixLen)
          suffixLen
          string;
      in builtins.substring
        0
        (stringLen - suffixLen)
        string;

    # Find all the names of the .nix files inside of the root
    nixFiles = builtins.filter
      (filename:
        (filesAndType."${filename}" == "regular")
        && (endsWith ".nix" filename))
      (builtins.attrNames filesAndType);

    nodes = builtins.map
      (withoutSuffix ".nix")
      nixFiles;

    importNode = name: builtins.toPath "${absRoot}/${name}.nix";

    # From a list of nodes: [ "node1" "node2" ]
    # import them all in to a dictionary, as:
    # { node1 = import ./root/node1.nix;
    #   node2 = import ./root/node2.nix;
    # }
    allImported = builtins.foldl'
      (collector: node: collector // { "${node}" = importNode node; })
      {}
      nodes;
  in allImported)
  // (import ../spotinst/interp.nix)
