# Flake-only nix. Do not add shrimp to trusted-users.
{ inputs, ... }:

{
  nixpkgs.config.allowUnfree = true; # VS Code, Copilot, Grok Bot, Grok Build
  nix.channel.enable = false;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Ad-hoc `nix run nixpkgs#foo` uses this flake's pin, not a floating channel.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  programs.command-not-found.enable = false;
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=512M
    SystemMaxFileSize=64M
  '';
}
