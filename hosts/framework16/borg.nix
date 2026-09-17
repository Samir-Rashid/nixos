# Borg is on PATH. The systemd job stays off until you have a *remote*
# repo and an agenix passphrase. Never point repo at this disk.
#
# Turn-on:
#   1. just secret borg-passphrase
#   2. set my.borg.repo = "ssh://…" / BorgBase / another machine
#   3. my.borg.enable = true
#   4. rebuild (doInit = true runs borg init)
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
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Borg repo URL. Must be off this disk: `ssh://user@host/path` or
        BorgBase `xxx@xxx.repo.borgbase.com:repo`. Required when enable = true.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.enable || (cfg.repo != null && cfg.repo != "");
        message = "my.borg.enable requires my.borg.repo (ssh://, BorgBase, or another machine — not this NVMe).";
      }
    ];

    environment.systemPackages = [ pkgs.borgbackup ];

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
      # Don't suspend mid-create; don't start the job on battery.
      inhibitsSleep = true;
      extraArgs = [ "--exclude-caches" ];
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      doInit = true;
    };

    systemd.services.borgbackup-job-home = lib.mkIf cfg.enable {
      unitConfig.ConditionACPower = "true";
    };
  };
}
