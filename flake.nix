{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {

      modules = [ ./configuration.nix 
          # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # TODO replace ryan with your own username
            home-manager.users.shrimp = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix
          }
];
#       homeConfigurations = {
#            "shrimp" = home-manager.lib.homeManagerConfiguration {
#                # System is very important!
#                pkgs = import nixpkgs { system = "x86_64-linux"; };
#
#                modules = [ ./configuration.nix ./home.nix ]; # Defined later
#            };
#        };

#      system = "x86_64-linux";
    };
  };
}
