let
  sources = import ./nix/sources.nix;
  overlay = _: pkgs: {
  };

  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
    config = {
      allowUnfree = true;
    };
  };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.jq
    pkgs.vault
    pkgs.niv
    pkgs.openssh
    pkgs.awscli
    pkgs.bashInteractive
    pkgs.git
    pkgs.morph
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
      (pkgs.buildGoModule rec {
        pname = "terraform-provider-rabbitmq";
        version = "1.5.1";
        goPackagePath = "github.com/cyrilgdn/terraform-provider-rabbitmq";
        subPackages = [ "." ];
        src = pkgs.fetchFromGitHub {
          owner = "cyrilgdn";
          repo = "terraform-provider-rabbitmq";
          rev = "v${version}";
          sha256 = "sha256-fqJEBIkAHqFgILAsMeTNqoZXyBGqDvnXL5sPc/OHu/s=";
        };
        preBuild = ''
          set -x
          if [ "x''${outputHashAlgo:-}" != x ]; then
             env
             rm -rf vendor
          fi
        '';
        vendorSha256 = "sha256-Oliwxv8L2ss9BD83HRfG7gWuqRVlC5gjZP5wiyYAJBo=";
        # Terraform allow checking the provider versions, but this breaks
        # if the versions are not provided via file paths.
        postBuild = ''
          mv $NIX_BUILD_TOP/go/bin/${pname}{,_v${version}}
        '';
      })
    ]))
  ];

  HISTFILE = "${toString ./.}/.bash_hist";
  NIX_PATH = "nixpkgs=${pkgs.path}:ofborg-infra=${toString ./.}";
}
