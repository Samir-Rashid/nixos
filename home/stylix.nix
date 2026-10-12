# User-side Stylix knobs. Palette/fonts/cursor are set on the NixOS module
# and inherited (followSystem). This file only names targets that Stylix
# cannot guess.
{
  # Firefox profiles we actually declared in firefox.nix.
  stylix.targets.firefox.profileNames = [ "default" ];

  # GNOME already owns look-and-feel. Stylix's qt target wants qtct, which
  # fights Adwaita. rofi is not installed; this pin still sets the
  # renamed programs.rofi.font option.
  stylix.targets.qt.enable = false;
  stylix.targets.rofi.enable = false;

  # HM 26.11 wants this explicit; Stylix still sets the theme/package.
  home.pointerCursor.enable = true;
}
