{
    network = {
    storage.s3 = {
      region = "us-east-1";
      bucket = "grahamc-nixops-state";
      key = "ofborg.nixops";
      kms_keyid = "166c5cbe-b827-4105-bdf4-a2db9b52efb4";
    };
  };
} // (import ./nixops/network.nix{
