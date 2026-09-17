# Flake-only nix. Do not add shrimp to trusted-users.
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
}
