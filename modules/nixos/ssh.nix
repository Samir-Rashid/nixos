# Laptop: no sshd. Keys stay so enabling later is one option flip.
{
  services.openssh.enable = false;

  users.users.shrimp.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OwPKXZmKH/djc29D/VFQFMopIzSDzlhc5Ywbu7RUO shrimp@framework16"
  ];
}
