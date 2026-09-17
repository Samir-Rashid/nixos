# Disko describes this machine's disk. Two different things:
#
#   1. This file is the *recipe* for a reinstall (`just disko` — destructive).
#   2. `disko.enableConfig` would also *generate* fileSystems/swap/luks from
#      it on every rebuild. That is OFF. Existing partitions have no GPT
#      labels, and `/` is the btrfs top-level, so we keep
#      hardware-configuration.nix as the live mount table.
#
# `nixos-rebuild switch` never formats disks. Only the disko CLI does.
{
  disko.enableConfig = false;

  disko.devices.disk.nvme = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HDLU-00B07_S77WNE0WB01922";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        luks-root = {
          # ~936G today. On a fresh install, `100%` minus swap is cleaner;
          # we pin the size so a reinstall matches this layout.
          size = "936G";
          content = {
            type = "luks";
            name = "luks-5cea4be3-ce05-434b-b05d-e4ae116fc729";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "root" ];
              subvolumes = {
                # Top-level mounted as /. Matches the current install.
                # After you migrate, change this mountpoint's subvol to "/sysroot".
                # Not named "/root": that collides with the root user's home
                # while `/` is still the top-level volume.
                "/" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                # Created empty; mounted only when my.impermanence.enable.
                "/persist" = { };
                "/sysroot" = { };
              };
            };
          };
        };
        luks-swap = {
          size = "100%";
          content = {
            type = "luks";
            name = "luks-1156e5f0-2b65-421d-9c5e-a0279c671b78";
            settings.allowDiscards = true;
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
        };
      };
    };
  };
}
