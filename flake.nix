{
  description = "shrimp's NixOS config — Framework 16 (AMD Ryzen 7040)";

  inputs = {
    # Pinned in flake.lock to 2026-07-14 (18b9261). Do not `just update-all`
    # or update stylix without nixpkgs (and vice versa): stylix master already
    # talks to services.displayManager.regreet, which this nixpkgs lacks.
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

    # Firefox add-ons (rycee). Not applied as a global overlay; see
    # modules/nixos/home-manager.nix extraSpecialArgs.firefoxAddons.
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Same week as nixpkgs (c8ccc31, July 2026). Never update stylix or
    # nixpkgs alone — see nixpkgs comment above.
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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
      nix-index-database,
      ...
    }@inputs:
    {
      # Must match networking.hostName and Justfile `uname -n` (framework16).
      nixosConfigurations.framework16 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nixos-hardware.nixosModules.framework-16-7040-amd
          impermanence.nixosModules.impermanence
          disko.nixosModules.disko
          agenix.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          nix-index-database.nixosModules.nix-index
          {
            nixpkgs.overlays = import ./overlays { inherit grok-bot-nix; };
          }
          ./hosts/framework16
        ];
      };

      packages.x86_64-linux.disko = disko.packages.x86_64-linux.disko;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
