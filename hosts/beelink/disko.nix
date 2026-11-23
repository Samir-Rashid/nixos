# Disk recipe. `disko.enableConfig` generates fileSystems / LUKS / swap.
# `nixos-rebuild` never formats; only the disko CLI does.
#
# Edit `disk` from `ls -l /dev/disk/by-id` on the Beelink before formatting.
# A missing by-id path makes disko stop. It does not guess another disk.
let
  disk = "/dev/disk/by-id/nvme-REPLACE_WITH_BEELINK_DISK";
in
{
  disko.enableConfig = true;

  disko.devices.disk.main = {
    type = "disk";
    device = disk;
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
        cryptswap = {
          size = "8G";
          content = {
            type = "luks";
            name = "cryptswap";
            settings.allowDiscards = true;
            content.type = "swap";
          };
        };
        cryptroot = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "nixos"
              ];
              subvolumes = {
                "/rootfs" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "ssd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "ssd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
