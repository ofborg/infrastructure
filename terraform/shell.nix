let
  sources = import ./nix/sources.nix;
  overlay = _: pkgs: {
  };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = {};
  };
in pkgs.mkShell {
  buildInputs = [
    pkgs.jq
    pkgs.vault
    pkgs.niv
    (pkgs.terraform_0_14.withPlugins (p: [
      (pkgs.buildGoModule rec {
        pname = "terraform-provider-cloudamqp";
        version = "1.8.6";
        goPackagePath = "github.com/cloudamqp/terraform-provider-cloudamqp";
        subPackages = [ "." ];
        src = pkgs.fetchFromGitHub {
          owner = "cloudamqp";
          repo = "terraform-provider-cloudamqp";
          rev = "v${version}";
          sha256 = "sha256-OxHvKoENhrPxg1uv/r92VXflroIRupJOZG64IGp4sok=";
        };
        preBuild = ''
         set -x
         if [ "x''${outputHashAlgo:-}" != x ]; then
            env
            rm -rf vendor
         fi
        '';
        vendorSha256 = "sha256-29Ys9YBShFutpZ1to4Zc+QJ4mtKvJQijrBuFRbpHjxE=";
        # Terraform allow checking the provider versions, but this breaks
        # if the versions are not provided via file paths.
        postBuild = ''
         mv $NIX_BUILD_TOP/go/bin/${pname}{,_v${version}}
        '';
      })
      (pkgs.buildGoPackage rec {
        pname = "terraform-provider-metal";
        version = "1.0.0";
        goPackagePath = "github.com/equinix/terraform-provider-metal";
        subPackages = [ "." ];
        src = pkgs.fetchFromGitHub {
          owner = "equinix";
          repo = "terraform-provider-metal";
          rev = "v1.0.0";
          sha256 = "sha256-wA3L0SEDWyU5OwrK+5W59Be9hNaC/gahu1fBaU5xmt4=";
        };
        # Terraform allow checking the provider versions, but this breaks
        # if the versions are not provided via file paths.
        postBuild = "mv go/bin/terraform-provider-metal{,_v1.0.0}";
      })
    ]))
  ];

  shellHook = ''
    export PACKET_AUTH_TOKEN=$(${pkgs.vault}/bin/vault kv get \
      -field api_key_token packet/creds/nixos-foundation)

    export CLOUDAMQP_APIKEY=$(${pkgs.vault}/bin/vault kv get \
      -field key secret/ofborg/cloudamqp.key)

    aws_creds=$(vault kv get -format=json aws-personal/creds/nixops-deploy)
    export AWS_ACCESS_KEY_ID=$(jq -r .data.access_key <<<"$aws_creds")
    export AWS_SECRET_ACCESS_KEY=$(${pkgs.jq}/bin/jq -r .data.secret_key <<<"$aws_creds")
    export AWS_SESSION_TOKEN=$(${pkgs.jq}/bin/jq -r .data.security_token <<<"$aws_creds")
    if [ -z "$AWS_SESSION_TOKEN" ] ||  [ "$AWS_SESSION_TOKEN" == "null" ]; then
      unset AWS_SESSION_TOKEN
    fi
    unset aws_creds
  '';
}

