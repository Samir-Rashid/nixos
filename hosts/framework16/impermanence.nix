# Impermanence is *wired in* but not turned on yet.
#
# Why: this install mounts `/` as the btrfs top-level volume (subvolid=5).
# `/home` and `/nix` are child subvolumes of that same filesystem. A
# boot-time "delete root and recreate it" script pointed at the top-level
# would be a great way to have a bad day.
#
# Intended end state (classic btrfs erase-your-darlings):
#   subvol=sysroot  → /          (wiped each boot, old copies kept ~30d)
#   subvol=home     → /home      (already exists, stays persistent)
#   subvol=nix      → /nix       (already exists, stays persistent)
#   subvol=persist  → /persist   (system state we opt into keeping)
#   ESP             → /boot
#
# Named sysroot, not root: while `/` is the top-level, `/root` is the
# root user's home, so a subvolume called `root` cannot be created.
#
# Home is *not* ephemeral. Your files, ssh keys, and browser profile live
# on the `home` subvolume. We only reset OS-level clutter under `/`.
#
# Flip these in default.nix after running scripts/create-persist-subvolume.sh:
#   my.impermanence.enable = true;         # after `persist` exists
#   my.impermanence.rollbackRoot = true;   # after `/` is subvol=sysroot
{
  config,
  lib,
  ...
}:

let
  luksRoot = "/dev/mapper/luks-5cea4be3-ce05-434b-b05d-e4ae116fc729";
  btrfsOpts = [
    "compress=zstd"
    "ssd"
    "noatime"
  ];
  cfg = config.my.impermanence;
in
{
  options.my.impermanence = {
    enable = lib.mkEnableOption ''
      Mount /persist and bind-mount the directories/files listed below.
      Requires a btrfs subvolume named `persist`. Safe without rollback:
      it only adds mounts, it does not wipe anything.
    '';

    rollbackRoot = lib.mkEnableOption ''
      On every boot, rename the `sysroot` subvolume aside and create a fresh
      one. Requires `/` to be mounted as subvol=sysroot, NOT the top-level.
    '';
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.rollbackRoot || cfg.enable;
          message = "my.impermanence.rollbackRoot requires my.impermanence.enable (you need /persist for state that must survive the wipe).";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      fileSystems."/persist" = {
        device = luksRoot;
        fsType = "btrfs";
        options = [ "subvol=persist" ] ++ btrfsOpts;
        # Bind mounts below happen in early boot; persist must be up first.
        neededForBoot = true;
      };

      # The module copies these from /persist/<path> → /<path> via bind mounts.
      # If something "forgets" settings after a reboot, add its directory here.
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/nixos" # uid/gid map — losing this remaps users. keep it.
          "/var/lib/systemd"
          "/var/lib/bluetooth"
          "/var/lib/fprint"
          "/var/lib/NetworkManager"
          "/etc/NetworkManager/system-connections"
          "/etc/ssh" # host keys; without this every reboot looks like a new machine
        ];
        files = [
          "/etc/machine-id"
          # mutableUsers (the default) stores the login hash here.
          # Alternative: users.users.shrimp.hashedPassword + mutableUsers = false.
          "/etc/shadow"
        ];
      };
    })

    (lib.mkIf cfg.rollbackRoot {
      # Point / at the dedicated root subvolume. hardware-configuration.nix
      # currently mounts the top-level; this option list is merged into it.
      fileSystems."/".options = [ "subvol=sysroot" ] ++ btrfsOpts;

      # postResumeCommands (not postDeviceCommands): running this on
      # hibernation resume can double-mount btrfs and corrupt the FS.
      # See nix-community/impermanence#250.
      boot.initrd.postResumeCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount ${luksRoot} /btrfs_tmp
        if [[ -e /btrfs_tmp/sysroot ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/sysroot)" "+%Y-%m-%d_%H:%M:%S")
            mv /btrfs_tmp/sysroot "/btrfs_tmp/old_roots/$timestamp"
        fi

        # rm -rf can delete btrfs subvolumes since kernel 4.17. Safer than
        # walking `btrfs subvolume list -o`, which has deleted the wrong
        # subvolumes in the wild (impermanence#250).
        find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} +

        btrfs subvolume create /btrfs_tmp/sysroot
        umount /btrfs_tmp
      '';
    })
  ];
}
