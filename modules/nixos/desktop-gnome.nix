{
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # The greeter is the gdm user, not shrimp, and its dconf db is on the
  # wiped root. Same housekeeping flag as home/gnome.nix, or the
  # donation notification is back at the login screen every boot.
  programs.dconf.profiles.gdm.databases = [
    {
      settings."org/gnome/settings-daemon/plugins/housekeeping" = {
        donation-reminder-enabled = false;
      };
    }
  ];
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
