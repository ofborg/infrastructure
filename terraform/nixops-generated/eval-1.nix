{
  deployment.targetHost = "195.201.33.185";
  terraform.name = "eval-1";
      hetzner.plan = "cx41";
    networking.hostName = "eval-1-lassulus.ewr1.nix.ci";

    roles.evaluator.enable = true;
  
}
