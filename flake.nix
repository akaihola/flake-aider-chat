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
        let
          pkgs = import nixpkgs { inherit system; };
          buildInputs = with pkgs; [
            pkgs.libsecret  # for secret-tool to manage API keys
            pkgs.nodejs  # for ESLint

            (pkgs.python3.withPackages (ps: with ps; [
              # https://aider.chat/docs/install/optional.html#enable-playwright
              # https://nixos.wiki/wiki/Playwright
              playwright  # instead of letting Aider install it
              playwright-driver
              playwright-driver.browsers
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

          AIDER_MODEL_METADATA_FILE = "${./claude-3.5-sonnet.metadata.json}";
          AIDER_MODEL_SETTINGS_FILE = "${./claude-3.5-sonnet.settings.yml}";
          AIDER_TEST_CMD = "${./run-tests.sh}";

          environmentSetupScript = ''
            ENV="''${XDG_CACHE_HOME:-''${HOME}/.cache}/aider-chat"
            VENV=$ENV/.venv
            export NPM_CONFIG_PREFIX=$ENV/.npm-global
            if [ ! -d $VENV ]; then
              python -m venv $VENV
            fi
            source $VENV/bin/activate
            export PATH=$NPM_CONFIG_PREFIX/bin:${./.}:$PATH
            export OPENROUTER_API_KEY="$(secret-tool lookup service openrouter.ai)"
            echo  # an empty line before usage instructions
          '';

          commonShellAttrs = {
            inherit
              buildInputs LD_LIBRARY_PATH
              PLAYWRIGHT_BROWSERS_PATH PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS PLAYWRIGHT_NODEJS_PATH
              AIDER_MODEL_METADATA_FILE AIDER_MODEL_SETTINGS_FILE AIDER_TEST_CMD;
          };
        in {
          default = pkgs.mkShell ( commonShellAttrs // {
            shellHook = environmentSetupScript + ''
              grep -B100 "^Once" ${./usage.md} | head --lines=-1
              exec aider --config=${./aider.conf.yml}
            '';
          });
          install = pkgs.mkShell ( commonShellAttrs // {
            shellHook = environmentSetupScript + ''
              exec aider-install
            '';
          });
          shell = pkgs.mkShell ( commonShellAttrs // {
            shellHook = environmentSetupScript + ''
              cat ${./usage.md}
              exec zsh
            '';
          });
        }
      );
    };
}