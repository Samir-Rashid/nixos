# Login shell is fish (set on the user). NixOS programs.fish.enable
# installs vendor completions; this module is the config.
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
