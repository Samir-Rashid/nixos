# Hyphenated extension names are not valid Nix identifiers, so they
# are looked up by string. A missing name fails the build.
{
  pkgs,
  ...
}:

let
  ext = pkgs.vscode-extensions;
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      extensions = map (p: ext.${builtins.elemAt p 0}.${builtins.elemAt p 1}) [
        [ "jnoortheen" "nix-ide" ]
        [ "mkhl" "direnv" ]
        [ "rust-lang" "rust-analyzer" ]
        [ "tamasfe" "even-better-toml" ]
        [ "serayuzgur" "crates" ]
        [ "golang" "go" ]
        [ "ms-python" "python" ]
        [ "ms-python" "vscode-pylance" ]
        [ "charliermarsh" "ruff" ]
        [ "ms-toolsai" "jupyter" ]
        [ "ms-toolsai" "jupyter-keymap" ]
        [ "ms-toolsai" "jupyter-renderers" ]
        [ "ms-vscode" "cpptools" ]
        [ "ms-vscode" "cpptools-extension-pack" ]
        [ "ms-vscode" "cmake-tools" ]
        [ "ms-vscode" "makefile-tools" ]
        [ "twxs" "cmake" ]
        [ "ms-azuretools" "vscode-docker" ]
        [ "ms-vscode-remote" "remote-ssh" ]
        [ "ms-vscode-remote" "remote-containers" ]
        [ "ms-vscode-remote" "remote-ssh-edit" ]
        [ "ms-vscode" "remote-explorer" ]
        [ "eamodio" "gitlens" ]
        [ "donjayamanne" "githistory" ]
        [ "github" "vscode-pull-request-github" ]
        [ "github" "copilot" ]
        [ "github" "copilot-chat" ]
        [ "dbaeumer" "vscode-eslint" ]
        [ "esbenp" "prettier-vscode" ]
        [ "streetsidesoftware" "code-spell-checker" ]
        [ "timonwong" "shellcheck" ]
        [ "usernamehw" "errorlens" ]
        [ "christian-kohler" "path-intellisense" ]
        [ "naumovs" "color-highlight" ]
        [ "ms-vsliveshare" "vsliveshare" ]
        [ "vscode-icons-team" "vscode-icons" ]
        [ "humao" "rest-client" ]
      ];
      userSettings = {
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.tabSize" = 2;
        "workbench.iconTheme" = "vscode-icons";
        "files.trimTrailingWhitespace" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
      };
    };
  };
}
