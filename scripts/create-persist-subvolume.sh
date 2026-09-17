#!/usr/bin/env bash
# One-time helper: create the btrfs subvolumes persist + sysroot.
#
# Safe: creates them next to the existing `home` and `nix` subvolumes.
# Does not move, snapshot, or delete `/`. Does not enable rollback.
#
# The ephemeral-root subvolume is named `sysroot`, not `root`. While `/` is
# the btrfs top-level, `/root` is the root user's home directory, so
# `btrfs subvolume create …/root` fails with "File exists".
#
# After persist exists:
#   set my.impermanence.enable = true;
#   rebuild
#
# Leave rollbackRoot = false. That path is not ready (systemd stage 1 does
# not accept postResumeCommands; subvol=sysroot must not be tied to wipe).
set -euo pipefail

DEV=/dev/mapper/luks-5cea4be3-ce05-434b-b05d-e4ae116fc729
MNT=$(mktemp -d)
cleanup() { sudo umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

if [[ ! -e "$DEV" ]]; then
  echo "LUKS mapper $DEV is not present. Are you on the Framework install?" >&2
  exit 1
fi

sudo -v

echo "Mounting btrfs top-level at $MNT"
sudo mount -o subvol=/ "$DEV" "$MNT"

echo
echo "Current subvolumes:"
sudo btrfs subvolume list "$MNT"
echo

is_subvol() {
  local name=$1
  sudo btrfs subvolume list "$MNT" | awk '{print $NF}' | grep -qx "$name"
}

create_subvol() {
  local name=$1
  if is_subvol "$name"; then
    echo "subvol $name already exists"
  elif [[ -e "$MNT/$name" ]]; then
    echo "ERROR: $MNT/$name exists and is not a btrfs subvolume." >&2
    echo "Refusing to clobber it. (If the name was 'root': that is /root, the" >&2
    echo "root user's home, because / is still the top-level volume.)" >&2
    exit 1
  else
    echo "creating subvol $name"
    sudo btrfs subvolume create "$MNT/$name"
  fi
}

create_subvol persist
create_subvol sysroot

echo
echo "Done. persist/ and sysroot/ exist on the top-level volume."
echo "They are NOT mounted yet."
echo
echo "Next, if you want /persist bind-mounts (no wipe):"
echo "  set my.impermanence.enable = true;  # leave rollbackRoot = false"
echo "  rebuild, confirm /persist mounts"
echo
echo "Do not enable rollbackRoot. Do not create a subvolume named root."
