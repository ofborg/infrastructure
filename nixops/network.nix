# /network.nix
{
  defaults = {
    imports = import ./modules;
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
