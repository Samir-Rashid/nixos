{
  description = "shrimp's NixOS config — Framework 16 (AMD Ryzen 7040)";

  inputs = {
    # Rolling NixOS. Pair home-manager with this, not a separate channel.
    # URL form matches the existing flake.lock pin so we don't surprise-bump nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Laptop quirks: AMD pstate, fingerprint, fwupd, keyboard HID, PSR workaround.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
      inputs.home-manager.follows = "";
    };

    # Declarative disk layout. nixos-rebuild does NOT format; only `disko` does.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # age-encrypted secrets, decrypted with SSH keys.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
      inputs.home-manager.follows = "home-manager";
    };

    # Firefox add-ons (rycee's set lives here). Overlay gives pkgs.nur.repos.rycee.
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # One palette/fonts/cursor for GNOME, ghostty, nvim, fish, …
    # Pinned to the same week as nixpkgs (July 2026). Master already
    # talks to services.displayManager.regreet, which this nixpkgs lacks.
    stylix = {
      url = "github:nix-community/stylix/c8ccc31f3ea29dc3eb5b54945e5eb549529491d6";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nur.follows = "nur";
    };

    # Grok Bot desktop app (Electron .deb). Overlay gives pkgs.grok-bot.
    grok-bot-nix = {
      url = "github:d-513/grok-bot-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      impermanence,
      disko,
      agenix,
      nur,
      stylix,
      grok-bot-nix,
      ...
    }@inputs:
    {
      # Attribute name must match networking.hostName for `nixos-rebuild --flake .`
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nixos-hardware.nixosModules.framework-16-7040-amd
          impermanence.nixosModules.impermanence
          disko.nixosModules.disko
          agenix.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              nur.overlays.default
              grok-bot-nix.overlays.default
              (final: _prev: {
                grok-build = final.callPackage ./pkgs/grok-build.nix { };
              })
            ];
          }
          ./hosts/framework16
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
