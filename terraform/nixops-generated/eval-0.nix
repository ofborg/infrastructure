{
  deployment.targetHost = "195.201.32.12";
  terraform.name = "eval-0";
      hetzner.plan = "cx41";
    networking.hostName = "eval-0-gleber.ewr1.nix.ci";

    roles.evaluator.enable = true;
  
}
