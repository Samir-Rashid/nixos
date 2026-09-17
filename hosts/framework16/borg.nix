# Borg is installed. The systemd backup *job* stays off until you have
# a repo URL and an agenix passphrase.
#
# Turn-on checklist:
#   1. just secret borg-passphrase     # encrypt a passphrase
#   2. set my.borg.repo to an ssh/local path
#   3. set my.borg.enable = true
#   4. rebuild, then: sudo borg-job-home init   (or doInit = true below)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.borg;
in
{
  options.my.borg = {
    enable = lib.mkEnableOption "daily borgbackup job for /home (needs repo + passphrase)";
    repo = lib.mkOption {
      type = lib.types.str;
      default = "/var/backup/borg";
      description = ''
        Borg repo URL. Local path, or `ssh://user@host/path`, or a BorgBase
        `xxx@xxx.repo.borgbase.com:repo`. Change this before enabling.
      '';
    };
  };

  config = {
    environment.systemPackages = [ pkgs.borgbackup ];

    # Decrypts to /run/agenix/borg-passphrase. Only referenced when enabled.
    age.secrets = lib.mkIf cfg.enable {
      borg-passphrase = {
        file = ../../secrets/borg-passphrase.age;
        owner = "root";
      };
    };

    services.borgbackup.jobs.home = lib.mkIf cfg.enable {
      paths = [ "/home/shrimp" ];
      exclude = [
        "/home/shrimp/.cache"
        "/home/shrimp/.local/share/Trash"
        "/home/shrimp/.npm"
        "/home/shrimp/.cargo/registry"
        "/home/shrimp/.rustup"
        "**/.direnv"
        "**/node_modules"
        "**/target"
        "/home/shrimp/.local/share/Steam"
      ];
      repo = cfg.repo;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.age.secrets.borg-passphrase.path}";
      };
      compression = "zstd,6";
      startAt = "daily";
      persistentTimer = true;
      # Laptop: don't spin the disk on battery.
      inhibitsSleep = false;
      extraArgs = [ "--exclude-caches" ];
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      # Set true once the repo exists; first run will `borg init` if true.
      doInit = true;
    };
  };
}
