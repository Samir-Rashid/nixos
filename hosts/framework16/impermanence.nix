# sysroot (/) is wiped each boot. ~/ is on sysroot; the whitelist below
# bind-mounts it back from /persist/home/shrimp. An unlisted path stays
# on that subvolume and is simply not mounted.
#
# A new bind needs `just rebuild-boot` and a reboot, not `just r`.
# Switch mounts the binds before /persist/home exists and covers ~/
# with empty directories until reboot.
{ ... }:

let
  cryptroot = "/dev/mapper/cryptroot";
in
{
  fileSystems."/persist".neededForBoot = true;
  # Before the binds. Same device as /persist, other subvolume.
  fileSystems."/persist/home".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    # GNOME trash on bind mounts (Documents and the other directories below).
    allowTrash = true;
    directories = [
      "/var/log"
      # Service uids (colord, cups, …). shrimp's uid is pinned.
      "/var/lib/nixos"
      # Not the whole directory: that keeps failed-unit state.
      # timers so Persistent= calendar jobs (nix gc) do not look missed
      # and fire on every boot.
      "/var/lib/systemd/timers"
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
      # systemd's entropy seed is a 32-byte file. Listing it as a
      # directory makes activation mkdir fail because the file exists.
      "/var/lib/systemd/random-seed"
    ];

    # Paths are relative to /home/shrimp. Stored at
    # /persist/home/shrimp/<path>, i.e. the old home subvolume.
    # Home Manager rewrites its own symlinks (.bashrc, nvim, git,
    # ghostty, gtk.css, vscode settings) each boot; those stay off
    # this list. ~/.cache stays off on purpose.
    users.shrimp = {
      directories = [
        "Documents"
        # Electron profile: cookies, sand-secrets, keyring-backed session.
        # ~/.grok is the CLI, not this app.
        ".config/Grok Bot"
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        # Firefox profile (places, cookies, containers). Cache is
        # ~/.cache/mozilla and is wiped.
        ".config/mozilla"
        ".local/share/fish"
        ".local/share/zoxide"
        ".local/state/wireplumber"
        ".local/state/nvim/undo"
        ".local/state/nvim/shada"
        # Sessions, memory, auth.json. The nix package is not in here.
        ".grok"
        # Linked device, keys, message db. Cache stays off.
        ".config/Signal"
        # Mail, keys, address book. profiles.ini is rewritten by Home Manager.
        ".thunderbird"
        # Rootless podman images and named volumes.
        ".local/share/containers"
      ];
      files = [
        ".config/gtk-3.0/bookmarks"
      ];
    };
  };

  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.services.rollback-sysroot = {
    description = "Rollback btrfs sysroot subvolume";
    wantedBy = [ "initrd.target" ];
    after = [
      "initrd-root-device.target"
      "systemd-hibernate-resume.service"
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
        find /btrfs_tmp/old_roots -mindepth 1 -maxdepth 1 -mtime +30 \
          -exec btrfs subvolume delete -R {} +
      fi
      btrfs subvolume create /btrfs_tmp/sysroot
      umount /btrfs_tmp
    '';
  };
}
