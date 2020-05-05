self: super: {
  mutate = script: args:
    (self.stdenvNoCC.mkDerivation (args // {
      name = baseNameOf script;
      phases = [ "installPhase" ];

      installPhase = ''
        cp -r ${script} $out
        for f in $(find $out -type f); do
          substituteAllInPlace $f
          patchShebangs $f
        done
      '';
    }));

  nginxVhostProxy = to: {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = to;
  };

  nginxVhostPHP = root: {
    enableACME = true;
    forceSSL = true;

    inherit root;

    locations = {
      "/" = {
        index = "index.php index.html";

        extraConfig = ''
          try_files $uri $uri/ /index.php$is_args$args;
        '';
      };

      "~ \.php$" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${super.config.services.phpfpm.pools.main.socket};
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME ${root}/$fastcgi_script_name;
          include ${self.nginx}/conf/fastcgi_params;
        '';
      };
    };
  };

  terraform-provider-nixos = self.callPackage ./terraform-provider-nixos.nix {};

  terraform-provider-hcloud = self.runCommand "terraform-provider-hcloud" {
    src = self.fetchzip {
      url = "https://github.com/hetznercloud/terraform-provider-hcloud/releases/download/v1.0.0/terraform-provider-hcloud_v1.0.0_linux_386.zip";
      stripRoot = false;
      sha256 = "0g7r52v56fdkfwzlxfhi00hjrxkpdgriccr7g1y5j4r7pyx1svkr";
    };
  } ''
    mkdir -p $out/bin
    cp $src/terraform-provider-hcloud $out/bin
  '';

  nixops = let
    newpkgs = import (self.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs-channels";
      rev = "05f0934825c2a0750d4888c4735f9420c906b388";
      sha256 = "1g8c2w0661qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
    }) {};

    nixops-poetry = newpkgs.poetry2nix.mkPoetryEnv {
      projectDir = ./poetry;
      overrides = newpkgs.poetry2nix.overrides.withDefaults (
        poetryself: poetrysuper: {
          zipp = poetrysuper.zipp.overridePythonAttrs(old: {
            propagatedBuildInputs = old.propagatedBuildInputs ++ [
              poetryself.toml
            ];
          });

          nixops = poetrysuper.nixops.overridePythonAttrs(old: {
            format = "pyproject";
            buildInputs = old.buildInputs ++ [ poetryself.poetry ];
          });

          nixops-packet = poetrysuper.nixops-packet.overridePythonAttrs(old: {
            format = "pyproject";
            buildInputs = old.buildInputs ++ [ poetryself.poetry ];
          });

          packet-python = poetrysuper.packet-python.overridePythonAttrs(old: {
            propagatedBuildInputs = old.propagatedBuildInputs ++ [
              poetryself.pytest-runner
            ];
          });
        }
      );
    };
  in nixops-poetry;
}
