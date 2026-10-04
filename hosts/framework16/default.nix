# Host: Framework Laptop 16, AMD Ryzen 7 7840HS.
# Generic NixOS lives in modules/nixos. Hardware quirks: nixos-hardware.
#
# Hostname lockstep: networking.hostName, nixosConfigurations.<name> in
# flake.nix, and Justfile's `uname -n` must stay identical (framework16).
{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/nixos
    ./hardware.nix
    ./disko.nix
    ./impermanence.nix
    ./borg.nix
    ./stylix.nix
  ];

  my.borg.enable = false;

  # --- boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 8;

  programs.nh = {
    enable = true;
    flake = "/home/shrimp/Documents/nix-config";
  };

  networking.hostName = "framework16";

  # --- users ---
  # Password hash lives on persist (created during install, see README).
  # Skip that step and GDM cannot log you in. Root has no password.
  programs.fish.enable = true;
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.shrimp = {
    isNormalUser = true;
    # Matches the files already on the home subvolume. Pinned so a
    # lost /var/lib/nixos cannot renumber this user. That directory
    # still holds dynamically allocated service uids.
    uid = 1000;
    description = "shrimp";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    hashedPasswordFile = "/persist/secrets/shrimp-password";
  };

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    just
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.firefox.enable = false;

  # Compatibility floor for a 26.11 install. Do not bump.
  system.stateVersion = "26.11";
}
