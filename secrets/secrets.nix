# Used ONLY by the `agenix` CLI (`just secret NAME`). NixOS does not import
# this file. It answers: "which public keys may decrypt each .age file?"
#
# Host key: after the first switch with openssh enabled,
#   cat /etc/ssh/ssh_host_ed25519_key.pub
# and add it to `systems`. Then `cd secrets && agenix --rekey`.
let
  shrimp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OwPKXZmKH/djc29D/VFQFMopIzSDzlhc5Ywbu7RUO shrimp@nixos";
  users = [ shrimp ];

  # systems = [ "ssh-ed25519 AAAA... root@nixos" ];
  systems = [ ];
in
{
  "borg-passphrase.age".publicKeys = users ++ systems;
}
