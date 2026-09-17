# Ephemeral `/` on btrfs. Disko mounts:
#   sysroot  → /         wiped each boot (old copies kept ~30d)
#   home     → /home     persistent (this flake lives here)
#   nix      → /nix      persistent
#   persist  → /persist  the whitelist below
#   ESP      → /boot
#
# Rollback is a systemd initrd unit. postResumeCommands is rejected on
# systemd stage 1. Ordered after local-fs-pre so it does not run on
# hibernate resume (nix-community/impermanence#250).
{ ... }:

let
  cryptroot = "/dev/mapper/cryptroot";
in
{
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/bluetooth"
      "/var/lib/fprint"
      "/var/lib/fwupd"
      "/var/lib/colord"
      "/var/lib/cups"
      "/var/lib/upower"
      "/var/lib/AccountsService"
      "/var/lib/NetworkManager"
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.services.rollback-sysroot = {
    description = "Rollback btrfs sysroot subvolume";
    wantedBy = [ "initrd.target" ];
    after = [
      "initrd-root-device.target"
      "local-fs-pre.target"
    ];
    before = [ "sysroot.mount" ];
    requires = [ "initrd-root-device.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /btrfs_tmp
      mount -o subvol=/ ${cryptroot} /btrfs_tmp
      if [[ -e /btrfs_tmp/sysroot ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date -u +%Y-%m-%d_%H:%M:%S)
        mv /btrfs_tmp/sysroot "/btrfs_tmp/old_roots/$timestamp"
      fi
      if [[ -d /btrfs_tmp/old_roots ]]; then
        find /btrfs_tmp/old_roots -mindepth 1 -maxdepth 1 -mtime +30 -print0 |
          while IFS= read -r -d "" old; do
            btrfs subvolume delete -R "$old"
          done
      fi
      btrfs subvolume create /btrfs_tmp/sysroot
      umount /btrfs_tmp
    '';
  };
}
