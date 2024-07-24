{
  description = "Flake providing dev shell for using aider-chat in NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {
      url = self.sourceInfo.url;
      
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              pkgs.libsecret  # for secret-tool to manage API keys
              pkgs.nodejs

#              # https://aider.chat/docs/install/optional.html#enable-playwright
#              # https://nixos.wiki/wiki/Playwright
#              playwright-driver.browsers

              (pkgs.python3.withPackages (ps: with ps; [
                #virtualenv
                #pip
                playwright  # instead of letting Aider install it
                playwright-driver
                playwright-driver.browsers
                #setuptools
                #wheel
              ]))
            ];
            # https://discourse.nixos.org/t/how-to-solve-libstdc-not-found-in-shell-nix/25458
            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib";

            # https://aider.chat/docs/install/optional.html#enable-playwright
            # https://nixos.wiki/wiki/Playwright
            PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
            # https://github.com/microsoft/playwright/issues/5501
            PLAYWRIGHT_NODEJS_PATH = "${pkgs.nodejs}/bin/node";

            AIDER_ENV_FILE = "${./aider.env}";
            AIDER_MODEL_METADATA_FILE = "${./claude-3.5-sonnet.metadata.json}";
            AIDER_MODEL_SETTINGS_FILE = "${./claude-3.5-sonnet.settings.yml}";
            AIDER_TEST_CMD = "${./run-tests.sh}";


            shellHook = ''
              ENV="''${XDG_CACHE_HOME:-''${HOME}/.cache}/aider-chat"
              VENV=$ENV/.venv
              export NPM_CONFIG_PREFIX=$ENV/.npm-global
              if [ ! -d $VENV ]; then
                python -m venv $VENV
              fi
              source $VENV/bin/activate
              export PATH=$NPM_CONFIG_PREFIX/bin:${./.}:$PATH

              echo "To install/upgrade Aider and Eslint, run this instead:"
              echo "nix develop the command: aider-install"

              export OPENROUTER_API_KEY="$(secret-tool lookup service openrouter.ai)"

              exec aider --config=${./aider.conf.yml} --verbose
            '';
          };
        }
      );
    };
}