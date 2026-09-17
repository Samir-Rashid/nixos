# Ghostty via Home Manager. Settings become ~/.config/ghostty/config.
# Docs: https://ghostty.org/docs/config/reference
{ ... }:

{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    # font-family, font-size, theme: Stylix writes these. Don't set them here
    # or you'll fight mkDefault and lose track of the single palette.
    settings = {
      window-padding-x = 8;
      window-padding-y = 8;
      confirm-close-surface = false;
      clipboard-paste-protection = false;
    };
  };
}
