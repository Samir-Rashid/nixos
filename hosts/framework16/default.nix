# Host: Framework Laptop 16, AMD Ryzen 7 7840HS.
# Hardware-specific bits come from nixos-hardware (imported in flake.nix).
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix
    ./disko.nix
    ./borg.nix
    ./stylix.nix
  ];

  # --- impermanence (off until the extra subvolumes exist) ---
  my.impermanence.enable = false;
  my.impermanence.rollbackRoot = false;

  # --- borg (off until repo + agenix passphrase exist) ---
  my.borg.enable = false;

  # Extra mount flags merged into the generated hardware-configuration.
  # zstd compression is free on a laptop SSD; noatime cuts write traffic.
  fileSystems."/".options = [
    "compress=zstd"
    "noatime"
  ];
  fileSystems."/home".options = [
    "compress=zstd"
    "noatime"
  ];
  fileSystems."/nix".options = [
    "compress=zstd"
    "noatime"
  ];

  # --- boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # /boot is a 1G ESP. Cap generations so it cannot fill up.
  boot.loader.systemd-boot.configurationLimit = 8;

  boot.initrd.luks.devices."luks-1156e5f0-2b65-421d-9c5e-a0279c671b78".device =
    "/dev/disk/by-uuid/1156e5f0-2b65-421d-9c5e-a0279c671b78";

  # --- nix ---
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Dedup store automatically. Cheap on this NVMe.
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # `nh os switch` instead of remembering nixos-rebuild flags.
  programs.nh = {
    enable = true;
    flake = "/home/shrimp/Documents/nix-config";
  };

  # --- identity ---
  networking.hostName = "nixos";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # --- networking ---
  # NetworkManager owns Wi-Fi (including wpa_supplicant). The installer also
  # set networking.wireless.enable, which conflicts; we leave that off.
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # --- desktop ---
  # NixOS 25.11+ names. GDM defaults to Wayland, which is what we want.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Electron apps (VS Code, Discord, …) should speak Wayland natively.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # --- audio ---
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  # Fingerprint + fwupd come from nixos-hardware. Enroll with:
  #   fprintd-enroll
  # Firmware:
  #   fwupdmgr refresh && fwupdmgr update

  # --- users ---
  # Vendor completions + /etc/shells. HM owns the actual fish config.
  programs.fish.enable = true;

  users.users.shrimp = {
    isNormalUser = true;
    description = "shrimp";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OwPKXZmKH/djc29D/VFQFMopIzSDzlhc5Ywbu7RUO shrimp@nixos"
    ];
  };

  # Generates /etc/ssh/ssh_host_ed25519_key on first switch. agenix uses that
  # to decrypt secrets at boot. Password auth off: this key is the only way in.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # --- home-manager (as a NixOS module) ---
  # One `nixos-rebuild switch` deploys the system *and* your home.
  # Standalone `home-manager switch` is the other style; we are not using it.
  home-manager = {
    useGlobalPkgs = true; # reuse this NixOS's pkgs (incl. allowUnfree)
    useUserPackages = true; # install user pkgs into /etc/profiles
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "bak"; # first switch won't die on existing dotfiles
    users.shrimp = import ../../home/shrimp.nix;
  };

  # System-wide packages. Prefer home.packages for user tools.
  environment.systemPackages = with pkgs; [
    git
    pciutils
    usbutils
    just
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Firefox lives in Home Manager (extensions, search, userChrome).
  programs.firefox.enable = false;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Do not bump this. It is a compatibility floor, not "current release".
  system.stateVersion = "26.05";
}
