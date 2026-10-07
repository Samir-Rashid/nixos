# Declarative GNOME bits Stylix does not set. Palette still comes from Stylix.
# ~/.config/dconf is not persisted, so anything absent here resets on boot
# (window sizes, last file-chooser directory).
{ pkgs, ... }:

{
  # Installs into the user profile and enables them. UUIDs come from
  # the packages, so a nixpkgs bump does not leave a stale id enabled.
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.steal-my-focus-window; }
      { package = pkgs.gnomeExtensions.desktop-cube; }
    ];
  };

  dconf.settings = {
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
    };
    # GNOME 49+ "Support GNOME" notification. last-shown is not
    # persisted, so the default fires again on every boot.
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      donation-reminder-enabled = false;
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
