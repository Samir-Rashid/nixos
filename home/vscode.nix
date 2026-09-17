# VS Code via Home Manager. nixpkgs packages a few hundred extensions;
# the marketplace has ~80k. `pick` skips anything not in this pin so a
# missing attr doesn't take down the whole system.
#
# Not brought over (on purpose):
#   TabNine                  — Copilot covers this
#   vscodevim + vscode-neovim — neovim only; one modal editor is enough
#   Java pack / checkstyle   — huge; add when you next open a Java repo
#   GitHub Classroom         — course-specific
#   vsliveshare-audio        — deprecated
#   black / isort / pylint   — ruff replaces all three
#   bungcip.better-toml      — dead; even-better-toml is the successor
#   Live Server, drawio, sshfs, checkpoints, arm, verilog, prisma, flutter
#     — add from the marketplace when you actually need them
#
# Added even though your old list didn't have them: nix-ide, direnv.
{
  pkgs,
  lib,
  ...
}:

let
  vs = pkgs.vscode-extensions;
  maybe =
    path:
    let
      ext = lib.attrByPath path null vs;
    in
    lib.optional (ext != null) ext;
  pick = paths: lib.concatMap maybe paths;
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      extensions = pick [
        [ "jnoortheen" "nix-ide" ]
        [ "mkhl" "direnv" ]
        [ "asvetliakov" "vscode-neovim" ]
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
        [ "DavidAnson" "vscode-markdownlint" ]
        [ "streetsidesoftware" "code-spell-checker" ]
        [ "timonwong" "shellcheck" ]
        [ "Gruntfuggly" "todo-tree" ]
        [ "usernamehw" "errorlens" ]
        [ "christian-kohler" "path-intellisense" ]
        [ "naumovs" "color-highlight" ]
        [ "ms-vsliveshare" "vsliveshare" ]
        [ "vscode-icons-team" "vscode-icons" ]
        [ "James-Yu" "latex-workshop" ]
        [ "humao" "rest-client" ]
        [ "VisualStudioExptTeam" "vscodeintellicode" ]
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
        "vscode-neovim.neovimExecutablePaths.linux" = "nvim";
      };
    };
  };
}
