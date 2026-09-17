# nix-config

Framework Laptop 16 (AMD Ryzen 7 7840HS). NixOS unstable, flakes.

This repo is the source of truth. Install from it; do not layer it onto an
existing installer disk. `nixos-rebuild switch` on the current machine
(hostname `nixos`, `/` as btrfs top-level) will not boot — Disko now owns
mounts as `subvol=sysroot` on `/dev/mapper/cryptroot`.

```
# after install:
nh os switch
# or
just r
```

## Install from scratch

Needs: this flake (git remote or USB), a NixOS installer ISO, Secure Boot
off, the Samsung NVMe still at the by-id path in `hosts/framework16/disko.nix`.

**This wipes the NVMe.** Two LUKS passphrases (swap then root); using the
same one is fine.

1. Boot the NixOS installer. Get a network. Clone or copy this repo and `cd`
   into it.

2. Confirm the disk:

   ```
   ls -l /dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HDLU-00B07_S77WNE0WB01922
   ```

   If that name moved, edit `disko.nix` before formatting.

3. Format and mount (pinned `disko` from this flake, not floating github):

   ```
   sudo nix --extra-experimental-features "nix-command flakes" run .#disko -- \
     --mode destroy,format,mount --flake .#framework16
   ```

   Layout: 1G ESP, 32G LUKS swap (`cryptswap`), rest LUKS btrfs (`cryptroot`)
   with subvolumes `sysroot` → `/`, `home`, `nix`, `persist`.

4. Login hash (read at activation from persist; not in git):

   ```
   sudo mkdir -p /mnt/persist/secrets
   mkpasswd -m yescrypt | sudo tee /mnt/persist/secrets/shrimp-password
   sudo chmod 600 /mnt/persist/secrets/shrimp-password
   ```

5. Install:

   ```
   sudo nixos-install --flake .#framework16
   ```

   Set a **root** password if asked — it is only for the installer session.
   The installed system has `root` locked (`hashedPassword = "!"`); shrimp
   sudoes.

6. Put the flake on the persistent home:

   ```
   sudo mkdir -p /mnt/home/shrimp/Documents
   sudo cp -a . /mnt/home/shrimp/Documents/nix-config
   sudo chown -R 1000:1000 /mnt/home/shrimp
   ```

7. `sudo umount -R /mnt`, reboot, pull the USB. Unlock LUKS, log in as
   `shrimp`. `findmnt /` should show `subvol=/sysroot`. `/persist` should be
   mounted. The next reboot wipes `sysroot`; home, nix, and persist stay.

8. After first login:

   ```
   fwupdmgr refresh && fwupdmgr update
   fprintd-enroll
   # if you later enable sshd / agenix host keys:
   # cat /etc/ssh/ssh_host_ed25519_key.pub  → secrets.nix systems → just rekey
   ```

## Layout

```
flake.nix                         inputs + nixosConfigurations.framework16
overlays/default.nix              grok-bot + grok-build (not NUR)
modules/nixos/                    nix, GNOME, locale, ssh (off), HM
Justfile                          just r / just build / just secret …
hosts/framework16/
  default.nix                     this machine
  hardware.nix                    kernel modules only
  disko.nix                       GPT + LUKS + btrfs; enableConfig = true
  impermanence.nix                persist whitelist + initrd rollback
  borg.nix                        borg job, off until a remote repo
  stylix.nix                      palette/fonts/cursor (catppuccin-mocha)
home/                             HM module (deployed by nixos-rebuild)
  firefox.nix                     addons from extraSpecialArgs.firefoxAddons
pkgs/grok-build.nix               grok CLI overlay (nixpkgs pin is 0.2.93)
secrets/secrets.nix               agenix recipients (CLI only)
```

`nixosConfigurations.framework16`, `networking.hostName`, and Justfile
`uname -n` must stay identical.

## Design

**Disko owns the disk.** `enableConfig = true` generates `fileSystems`,
LUKS, and swap. `hardware.nix` is modules and CPU only. Formatting is the
disko CLI in the install section, never `nixos-rebuild`.

**Ephemeral `/`.** `sysroot` is wiped in initrd (systemd unit
`rollback-sysroot`, not `postResumeCommands`). `/home` and `/nix` stay.
State that must survive is the list in `impermanence.nix` plus
`/persist/secrets/shrimp-password`. Full-home impermanence is a later
project.

**Home Manager is a NixOS module.** One rebuild deploys OS and home.
`useGlobalPkgs` shares `pkgs` (including `allowUnfree`). Firefox add-ons
are `extraSpecialArgs.firefoxAddons` (NUR rycee), not a global overlay.

**nixos-hardware `framework-16-7040-amd`.** AMD pstate, fingerprint, fwupd,
PSR workaround, keyboard HID. Do not re-encode those.

**GNOME + GDM on Wayland.** NetworkManager only (not `networking.wireless`).
`NIXOS_OZONE_WL=1` for Electron. sshd is off.

**Neovim via `programs.neovim`.** Servers in `extraPackages`, not mason.nvim.

**Stylix** is the one palette. NixOS module only (it auto-imports into HM).
`enableReleaseChecks` is off: nixpkgs and stylix are July 2026 pins, not a
named release pair.

**Fish** is login + interactive. NixOS `programs.fish.enable` for vendor
completions; HM owns the config.

**`stateVersion` is `26.11`.** Compatibility floor, not "current release".
Do not bump.

## Everyday commands

```
just              # list recipes
just build        # ./result, do not switch
just r            # nixos-rebuild switch --flake .#$(uname -n)
just rebuild boot
just update nixpkgs
just secret borg-passphrase
just fmt
```

## Grok Bot + Grok Build

Unfree; `allowUnfree` is on.

Grok Bot is `github:d-513/grok-bot-nix` (`pkgs.grok-bot`). Needs
`home.packages` so the `.desktop` file is on `XDG_DATA_DIRS` (`sand://` /
`grokbot://`). In-app update does not work:

```
just update grok-bot-nix
just r
```

Grok Build (`grok` / `agent`) is `pkgs/grok-build.nix`. This nixpkgs pin
still has 0.2.93; bump `version` + `hash` there. `GROK_DISABLE_AUTOUPDATER=1`.

## agenix

`secrets/secrets.nix` is **not** imported by NixOS; only the CLI reads it.

Encrypt today with the user key in that file. After install, add
`/etc/ssh/ssh_host_ed25519_key.pub` to `systems` and `just rekey`. Without
the host key as a recipient, activation cannot decrypt secrets.

## Borg

`my.borg.enable` is false. When you have a **remote** repo:

1. `just secret borg-passphrase`
2. set `my.borg.repo` and `my.borg.enable = true`
3. rebuild

`my.borg.repo` has no default; enable requires a remote URL.

## Later

Hyprland, Tailscale, 1Password, Steam, `nix-vscode-extensions`, NVIDIA
expansion module if you seat the dGPU.
