# Overlays applied to this system's pkgs. NUR is not here: Firefox add-ons
# are passed into Home Manager via extraSpecialArgs (see modules/nixos/home-manager.nix).
{ grok-bot-nix }:

[
  grok-bot-nix.overlays.default
  (final: _prev: {
    grok-build = final.callPackage ../pkgs/grok-build.nix { };
  })
]
