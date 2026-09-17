# Disk recipe. `disko.enableConfig` generates fileSystems / LUKS / swap
# from this. `nixos-rebuild` never formats; only the disko CLI does
# (see README install).
{
  disko.enableConfig = true;

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
        cryptswap = {
          size = "32G";
          content = {
            type = "luks";
            name = "cryptswap";
            settings.allowDiscards = true;
            content = {
              type = "swap";
              # Hibernate to this LUKS swap. Rollback waits on
              # systemd-hibernate-resume so a resume does not wipe sysroot.
              resumeDevice = true;
            };
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
                # Not named "root": that collides with the root user's home
                # if the top-level is ever mounted at /.
                "/sysroot" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "ssd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
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
                "/persist" = {
                  mountpoint = "/persist";
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
