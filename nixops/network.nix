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
  network = {
    storage.s3 = {
      region = "us-east-1";
      bucket = "grahamc-nixops-state";
      key = "ofborg.nixops";
      kms_keyid = "166c5cbe-b827-4105-bdf4-a2db9b52efb4";
    };
  };
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
  // {
    hetzner-sb65-1083082-hel1-dc2 = {
      deployment.targetEnv = "none";
      deployment.targetHost = "95.216.99.249";

      nix.gc_free_gb = 100;
      services.ofborg.builder.enable = true;
      services.ofborg.evaluator.enable = true;

      boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];
      services.openssh.enable = true;
      networking.hostId = "81bf6083";
      networking.useDHCP = false;
      networking.interfaces.enp27s0.useDHCP = true;
      boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
        { device = "rpool/safe/root";
        fsType = "zfs";
        };

      fileSystems."/nix" =
        { device = "rpool/local/nix";
        fsType = "zfs";
        };

      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/3d7d6997-82df-4976-9f8c-057731c1234b";
        fsType = "ext4";
        };

      swapDevices = [ ];

      nix.maxJobs = 16;
    };

    resources.packetKeyPairs.dummy = {
      project = "86d5d066-b891-4608-af55-a481aa2c0094";
    };
    packet-spot-eval-1 = { resources, ... }: {
      deployment.targetEnv = "packet";
      deployment.packet = {
        project = "86d5d066-b891-4608-af55-a481aa2c0094";
        keyPair = resources.packetKeyPairs.dummy;
        facility = "ewr1";
        plan = "m1.xlarge.x86";
        ipxeScriptUrl = "http://139.178.89.161/current/907e8786.packethost.net/result/x86/netboot.ipxe";
        spotInstance = true;
        spotPriceMax = "2.00";
        tags = {
          buildkite = "...yes...";
        };
      };

      nix.gc_free_gb = 100;
      services.ofborg.builder.enable = true;
      services.ofborg.evaluator.enable = true;

      nix.buildCores = 24;
    };
    packet-spot-eval-2 = { resources, ... }: {
      deployment.targetEnv = "packet";
      deployment.packet = {
        project = "86d5d066-b891-4608-af55-a481aa2c0094";
        keyPair = resources.packetKeyPairs.dummy;
        facility = "ewr1";
        plan = "m1.xlarge.x86";
        ipxeScriptUrl = "http://139.178.89.161/current/907e8786.packethost.net/result/x86/netboot.ipxe";
        spotInstance = true;
        spotPriceMax = "2.00";
        tags = {
          buildkite = "...yes...";
        };
      };

      nix.gc_free_gb = 100;
      services.ofborg.builder.enable = true;
      services.ofborg.evaluator.enable = true;

      nix.buildCores = 24;
    };
    packet-spot-eval-3 = { resources, ... }: {
      deployment.targetEnv = "packet";
      deployment.packet = {
        project = "86d5d066-b891-4608-af55-a481aa2c0094";
        keyPair = resources.packetKeyPairs.dummy;
        facility = "ewr1";
        plan = "m1.xlarge.x86";
        ipxeScriptUrl = "http://139.178.89.161/current/907e8786.packethost.net/result/x86/netboot.ipxe";
        spotInstance = true;
        spotPriceMax = "2.00";
        tags = {
          buildkite = "...yes...";
        };
      };

      nix.gc_free_gb = 100;
      services.ofborg.builder.enable = true;
      services.ofborg.evaluator.enable = true;

      nix.buildCores = 24;
    };

  }
