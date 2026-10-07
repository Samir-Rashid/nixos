# Home Manager config for user `shrimp`.
# This is imported by modules/nixos/home-manager.nix,
# so it is applied on `nixos-rebuild switch` / `nh os switch`.
{ pkgs, ... }:

{
  imports = [
    ./neovim.nix
    ./ghostty.nix
    ./firefox.nix
    ./vscode.nix
    ./thunderbird.nix
    ./fish.nix
    ./stylix.nix
    ./grok.nix
    ./gnome.nix
  ];

  home.username = "shrimp";
  home.homeDirectory = "/home/shrimp";

  home.packages = with pkgs; [
    fastfetch
    ripgrep
    fd
    jq
    eza
    fzf
    bat
    btop
    gh
    wl-clipboard # neovim clipboard=unnamedplus on Wayland
    keepassxc # native host for keepassxc-browser
    tree
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Samir Rashid";
        email = "Samir-Rashid@godsped.com";
        signingKey = "~/.ssh/id_ed25519.pub";
      };
      pull.rebase = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
      commit.gpgsign = true;
    };
  };

  programs.zoxide.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      cat = "bat";
      rebuild = "nh os switch";
    };
  };

  programs.starship.enable = true;
  # Fish/bash integrations default on when those shells are enabled.

  # Per-project nix shells, plus a cache so direnv isn't slow.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # `nom` on PATH, and fish wraps `nix build` / `shell` / `develop` with it.
  # `nh os switch` already calls nom unless passed --no-nom.
  programs.nix-your-shell = {
    enable = true;
    enableFishIntegration = true;
    nix-output-monitor.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "ghostty";
  };

  # GNOME color-scheme / GTK / cursor come from Stylix now.

  # Compatibility floor, same generation as system.stateVersion. Do not bump.
  home.stateVersion = "26.11";
}
