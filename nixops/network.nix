{
  defaults = { nodes, lib, ... }: {
    imports = import ./modules;

    services.ofborg.rabbitmq.cluster_ips = let
        ipIf = filter: nodes:
          map (node: node.config.deployment.targetHost)
              (lib.filter filter (lib.attrValues nodes));
      in ipIf
          (node: node.config.services.ofborg.rabbitmq.enable)
          nodes;

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
  // (
  let
    numMachines = last:
      let
        last' =
          if last == "" then
            3 # if OFBORG_PACKET_HOSTS is unspecified, use this amount by default
          else
            if builtins.isInt last then last else builtins.fromJSON last;
      in
      builtins.genList (n: n + 1) last';

    mkEvaluator = n: {
      name = "packet-spot-eval-${toString n}";
      value = { resources, ... }: {
        deployment.targetEnv = "packet";
        deployment.packet = {
          project = "86d5d066-b891-4608-af55-a481aa2c0094";
          keyPair = resources.packetKeyPairs.dummy;
          facility = "ewr1";
          plan = "m1.xlarge.x86";
          ipxeScriptUrl = "http://images.packet.net/nixos/installer-pre/x86/netboot.ipxe";
          spotInstance = true;
          spotPriceMax = "2.00";
          tags = { buildkite = "...yes..."; };
        };

        services.ofborg.builder.enable = true;
        services.ofborg.evaluator.enable = true;

        nix.gc_free_gb = 100;
        nix.buildCores = 24;
      };
    };
  in
  {
    resources.packetKeyPairs.dummy = {
      project = "86d5d066-b891-4608-af55-a481aa2c0094";
    };
  } //
  builtins.listToAttrs (
    map
      (n: mkEvaluator n)
      (numMachines (builtins.getEnv "OFBORG_PACKET_HOSTS"))
  )
)
