{
  deployment.targetHost = "195.201.97.38";
  terraform.name = "eval-2";
      hetzner.plan = "cx41";
    networking.hostName = "eval-2-shlevy.ewr1.nix.ci";

    roles.evaluator.enable = true;
  
}
