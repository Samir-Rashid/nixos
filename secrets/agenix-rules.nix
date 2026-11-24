# Used ONLY by the `agenix` CLI (`just secret NAME`). NixOS does not import
# this file. It answers: "which public keys may decrypt each .age file?"
#
# Host key: after the first switch with openssh enabled,
#   cat /etc/ssh/ssh_host_ed25519_key.pub
# and add it to `systems`. Then `cd secrets && agenix --rekey`.
let
  # ~/.ssh/id_ed25519.pub on this machine. sshd is off, so this is also
  # the key agenix uses to decrypt at activation.
  shrimp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEjWclDRh9IvfLUzdlww+apW8JedSYvrxgvPtYmU/Ry7 shrimp@framework16";
  users = [ shrimp ];

  # systems = [ "ssh-ed25519 AAAA... root@nixos" ];
  systems = [ ];
in
{
  "borg-passphrase.age".publicKeys = users ++ systems;
  "nordvpn-private-key.age".publicKeys = users ++ systems;
}
