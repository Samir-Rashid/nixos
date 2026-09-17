# Home Manager as a NixOS module. Firefox add-ons come from NUR without
# applying the NUR overlay to the whole package set.
{
  inputs,
  pkgs,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      firefoxAddons = (pkgs.extend inputs.nur.overlays.default).nur.repos.rycee.firefox-addons;
    };
    users.shrimp = import ../../home/shrimp.nix;
  };
}
