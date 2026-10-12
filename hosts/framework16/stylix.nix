# Stylix is the *one* place colors, fonts, and the cursor are chosen.
# Targets (ghostty, nvim, fish, GNOME, …) follow this automatically
# because we use Home Manager as a NixOS module (autoImport + followSystem).
#
# Do not also import stylix.homeModules.stylix — that duplicates options.
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    polarity = "dark";
    # GDM, not ReGreet. This stylix pin still assigns programs.regreet,
    # which this nixpkgs renamed to services.displayManager.regreet.
    targets.regreet.enable = false;
    # Same mocha you already had in ghostty/nvim. Swap the yaml to restyle
    # the whole machine: `ls ${pkgs.base16-schemes}/share/themes`
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes.terminal = 12;
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Copied from ~/Downloads/wallpaper.jpeg. Palette stays the mocha
    # scheme above; the image is only the background.
    image = ./wallpaper.jpeg;
  };
}
