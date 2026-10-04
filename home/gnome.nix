# Declarative GNOME bits Stylix does not set. Palette still comes from Stylix.
# ~/.config/dconf is not persisted, so anything absent here resets on boot
# (window sizes, last file-chooser directory).
{ pkgs, ... }:

{
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/shell" = {
      last-selected-power-profile = "power-saver";
      # Compared to the running Shell version. Tracks this pin, so a
      # GNOME bump does not make the welcome tour run on every boot.
      welcome-dialog-last-shown-version = pkgs.gnome-shell.version;
    };
  };

  # Initial setup only checks that this file exists.
  xdg.configFile."gnome-initial-setup-done".text = "yes\n";
}
