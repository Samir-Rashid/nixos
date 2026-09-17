# Fish as the interactive shell. Login shell is also fish (set on the
# NixOS user). Bash stays enabled below in shrimp.nix for POSIX scripts.
#
# NixOS `programs.fish.enable` (host) is what puts vendor completions
# into /etc. This HM module is the actual config: aliases, greeting, hooks.
{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    # Generating completions from every man page is slow and noisy.
    # Vendor completions from NixOS `programs.fish.enable` still work.
    generateCompletions = false;
    interactiveShellInit = ''
      set fish_greeting
    '';
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      cat = "bat";
      rebuild = "nh os switch";
    };
    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];
  };
}
