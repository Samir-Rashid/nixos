# Rootless podman. `docker` calls podman, for the VS Code Docker extension.
# Images and volumes are ~/.local/share/containers, kept in impermanence.nix.
{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    # Containers on the default network can resolve each other by name.
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = [ pkgs.podman-compose ];

  # `postgres:16` and `axllent/mailpit` have no registry host. Podman will
  # not guess one unless this list is set. docker.io matches Docker.
  virtualisation.containers.registries.settings."unqualified-search-registries" = [ "docker.io" ];
}
