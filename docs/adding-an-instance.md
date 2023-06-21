1. `./enter-env.sh`
1. Increment the variable that controls the number of evaluators in `terraform/base/variables.tf`
1. `terraform apply`
1. Once the instance is reachable (it may take a while after terraform finishes due to IPXE booting), run the `make-targets.sh` script from the root of the repo 
1. `morph deploy ./morph-network/default.nix --on='ofborg-evaluator-XYZ' dry-activate`
1. `morph deploy ./morph-network/default.nix --on='ofborg-evaluator-XYZ' test`
1. `morph upload-secrets ./morph-network/default.nix --on='ofborg-evaluator-XYZ'`
1. `morph deploy ./morph-network/default.nix --on='ofborg-evaluator-XYZ' test`
    - This needs to be run twice because the secrets are chown'd to a user that doesn't exist until the system activates and creates them, and the ofborg units will fail to start up without that secret. Chicken-and-egg.
1. If it worked, make it permanent: `morph deploy ./morph-network/default.nix --on='ofborg-evaluator-XYZ' switch`
