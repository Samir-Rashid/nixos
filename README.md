# nix-config

Framework Laptop 16 (AMD Ryzen 7 7840HS), NixOS unstable, flakes.

This repo is the source of truth. `/etc/nixos` is leftover from the installer
and can be ignored.

```
sudo nixos-rebuild switch --flake .
# or, after this config is active:
nh os switch
```

Do not rebuild until you have read the design notes below. The config is
written so `nix build` can test it without activating anything.

## Layout

```
flake.nix                         inputs + nixosConfigurations.nixos
Justfile                          just r / just build / just secret …
hosts/framework16/
  default.nix                     this machine
  hardware-configuration.nix      live mounts (installer)
  disko.nix                       disk recipe, enableConfig = false
  impermanence.nix                persist/rollback, both off
  borg.nix                        borg job, off until repo + passphrase
  stylix.nix                      palette/fonts/cursor (catppuccin-mocha)
home/
  shrimp.nix                      git, bash, starship, direnv
  grok.nix                        grok-bot + grok-build
  firefox.nix / vscode.nix / thunderbird.nix / neovim.nix / ghostty.nix / fish.nix
pkgs/grok-build.nix               overlay: current grok CLI (nixpkgs pin is 0.2.93)
secrets/secrets.nix               agenix recipients (CLI only)
```

A flake has **inputs** (pinned elsewhere) and **outputs** (what we produce).
`flake.lock` freezes every input to a git revision. `nix flake update` moves
those pins; you usually update one input at a time.

`nixosConfigurations.nixos` is the system. The attribute name matches
`networking.hostName`, which is how `nixos-rebuild --flake .` finds it.

## Design decisions

**Home Manager is a NixOS module, not standalone.** One rebuild deploys the
OS and your home. `home-manager switch` is a different workflow (dotfiles on
a machine you do not control). `useGlobalPkgs` means HM uses the same
`pkgs` as NixOS, including `allowUnfree`.

**nixos-hardware for `framework-16-7040-amd`.** This is the official quirk
set: AMD pstate, power-profiles-daemon, fingerprint, fwupd, the AMD PSR hang
workaround, Framework keyboard HID udev rules. We do not re-encode those by
hand.

**GNOME stays.** You already have it. Hyprland is a later choice, not a
prerequisite.

**NetworkManager only.** The installer left `networking.wireless.enable =
true` next to NetworkManager. Those two fight over wpa_supplicant. GNOME
expects NM.

**Neovim via `programs.neovim`, not nixvim.** You can read the lua. Plugins
come from `pkgs.vimPlugins`. Language servers go in `extraPackages` (do not
use mason.nvim — it downloads binaries that ignore the Nix store). nixvim or
nvf are reasonable later if this file grows teeth.

**Ghostty via `programs.ghostty`.** Settings are Nix attrs that HM writes to
`~/.config/ghostty/config`. Font and theme come from Stylix.

**Stylix** is the single palette (catppuccin-mocha), fonts, and cursor.
Imported only as a NixOS module; it auto-imports into Home Manager. Do not
also import the HM module. `enableReleaseChecks` is off because nixpkgs is
pinned older than stylix master.

**Fish** is the login + interactive shell. NixOS `programs.fish.enable` is
required for vendor completions; HM `programs.fish` is the config. Bash
stays enabled for POSIX scripts. Starship is the prompt.

**Impermanence is configured, not armed.** See the next section.

**`system.stateVersion` stays `26.05`.** It is a compatibility floor for
stateful data, not "the release I am on". Same idea for
`home.stateVersion = "26.11"`.

## Impermanence (read this)

Your disk today:

| mount | btrfs subvolume | fate |
|-------|-----------------|------|
| `/` | top-level (id 5) | must not wipe |
| `/home` | `home` | persistent |
| `/nix` | `nix` | persistent |
| `/boot` | ESP | persistent |
| *(none)* | `persist` / `sysroot` | created empty by the helper script |
| `/srv`, `/tmp`, `/var/tmp`, `/var/lib/{portables,machines}` | installer/systemd leftovers | leave them |

Wiping `/` while it is the top-level volume would also take `home` and `nix`
with it. So both flags in `hosts/framework16/default.nix` are `false`.

The ephemeral-root subvolume is named **`sysroot`**, not `root`. While `/`
is the top-level, `/root` is the root user's home, so `btrfs subvolume
create …/root` fails with "File exists".

Intended layout, when you are ready:

- `sysroot` → `/` (fresh each boot, old copies kept ~30 days)
- `home` → `/home` (your files stay; we are **not** making `$HOME` ephemeral)
- `nix` → `/nix`
- `persist` → `/persist` (only the paths listed in `impermanence.nix`)
- ESP → `/boot`

Steps, in order:

1. Review `hosts/framework16/impermanence.nix`.
2. `./scripts/create-persist-subvolume.sh` — creates empty `persist` and
   `sysroot` subvolumes. Does not change mounts. Idempotent.
3. Set `my.impermanence.enable = true;`, rebuild, confirm `/persist` mounts.
   Leave `rollbackRoot = false`.
4. Do **not** enable `rollbackRoot` yet. That option still uses
   `boot.initrd.postResumeCommands`, which this nixpkgs rejects (systemd
   stage 1). Live-migrating `/` onto `sysroot` is a separate project, after
   backups.

`/home` stays a real subvolume on purpose. Full-home impermanence is a
separate, much more annoying project (`~/.ssh`, browser profiles, GNOME
dconf, every app's `~/.local/share/...`).

## Trying this without switching

```
nix -L build .#nixosConfigurations.nixos.config.system.build.toplevel
```

That builds a system closure and leaves a `./result` symlink. It does **not**
change the running generation. `ls result` is the new `/run/current-system`
you would get after `switch`.

## After you switch

```
fwupdmgr refresh && fwupdmgr update    # Framework firmware
fprintd-enroll                         # fingerprint
```

## Everyday commands (`just`)

```
just              # list recipes
just build        # build ./result, do not switch
just r            # alias: just rebuild  (switch)
just rebuild boot
just update nixpkgs
just secret borg-passphrase
just fmt
```

## Grok Bot + Grok Build

Both are unfree binaries. `allowUnfree` is already on.

**Grok Bot** (desktop) comes from `github:d-513/grok-bot-nix`. The overlay
puts `pkgs.grok-bot` on your PATH and `XDG_DATA_DIRS` so `sand://` /
`grokbot://` login redirects work. Wayland is already covered by
`NIXOS_OZONE_WL`. The in-app updater does not work under Nix:

```
just update grok-bot-nix
just r
```

**Grok Build** (`grok` / `agent`) is overlaid in `pkgs/grok-build.nix`.
This flake's nixpkgs pin still has 0.2.93; the overlay matches the 1.0.x
you already run from `~/.grok/bin`. Bump `version` + `hash` there when
you want a newer CLI. `GROK_DISABLE_AUTOUPDATER=1` is set so the TUI
does not fight the store.

## agenix

`secrets/secrets.nix` lists who can decrypt. It is **not** imported by NixOS;
only the `agenix` CLI reads it.

A user ed25519 key was generated at `~/.ssh/id_ed25519` so you can encrypt
secrets today. After the first switch, openssh writes a host key — add that
pubkey to `systems` in `secrets.nix` and `just rekey`. Without the host key
in the recipient list, activation cannot decrypt secrets.

## Borg

`my.borg.enable` is false. When you have a repo (BorgBase, another machine,
or `/var/backup/borg`):

1. `just secret borg-passphrase`
2. set `my.borg.repo` and `my.borg.enable = true`
3. rebuild

## Disko

`hosts/framework16/disko.nix` matches this Samsung 1TB NVMe (1G ESP, LUKS
btrfs, LUKS swap). `disko.enableConfig = false`: live mounts still come from
`hardware-configuration.nix`. `just disko` refuses to run; formatting is a
separate, destructive CLI.

## Ideas for next

| thing | why |
|-------|-----|
| **stylix** | one theme for GNOME + ghostty + nvim |
| **Hyprland** | if GNOME starts to feel like someone else's computer |
| **tailscale** | overlay network to other machines |
| **1Password** | `programs._1password` + `_1password-gui` |
| **steam** | `programs.steam.enable` (unfree, 32-bit) |
| **nix-vscode-extensions** | marketplace extensions nixpkgs doesn't package |
| **NVIDIA dGPU module** | only if you seat the FW16 NVIDIA expansion |

Firmware and fingerprint are already enabled by nixos-hardware. You just have
to run the two commands above once.
