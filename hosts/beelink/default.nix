# Host: Beelink NUC home server.
# Generic NixOS lives in modules/nixos. This machine does not import that
# barrel: it is GNOME, the Framework kernel workaround, and LinkServer.
#
# Hostname lockstep: networking.hostName, nixosConfigurations.beelink,
# and Justfile's `uname -n` must stay identical (beelink).
{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/nixos/nix.nix
    ../../modules/nixos/locale.nix
    ./hardware.nix
    ./disko.nix
    ./services.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 8;

  programs.nh = {
    enable = true;
    flake = "/home/shrimp/Documents/code/nixos";
  };

  networking.hostName = "beelink";
  networking.useDHCP = true;

  programs.fish.enable = true;
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.shrimp = {
    isNormalUser = true;
    uid = 1000;
    description = "shrimp";
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    # Created during install, mode 600. Not in git.
    hashedPasswordFile = "/var/lib/secrets/shrimp-password";
    openssh.authorizedKeys.keys = [
      # Same key as modules/nixos/ssh.nix.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OwPKXZmKH/djc29D/VFQFMopIzSDzlhc5Ywbu7RUO shrimp@framework16"
    ];
  };

  # sshd is off on the laptop. This host is reached over the network.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.forgejo-lts
    pkgs.just
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Compatibility floor for a 26.11 install. Do not bump.
  system.stateVersion = "26.11";
}
