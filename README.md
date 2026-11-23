# nix-config

Framework Laptop 16 (AMD Ryzen 7 7840HS) and a Beelink NUC (`beelink`).
NixOS unstable, flakes. `just r` builds `.#$(uname -n)`.

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
   with subvolumes `sysroot` → `/`, `home` → `/persist/home`, `nix`, `persist`.

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

6. Put the flake on the persistent home subvolume. That subvolume is
   mounted at `/persist/home`, not `/home` (`/home` is on `sysroot` and
   the next boot wipes it):

   ```
   sudo mkdir -p /mnt/persist/home/shrimp/Documents
   sudo cp -a . /mnt/persist/home/shrimp/Documents/nix-config
   sudo chown -R 1000:1000 /mnt/persist/home/shrimp
   ```

7. `sudo umount -R /mnt`, reboot, pull the USB. Unlock LUKS, log in as
   `shrimp`. `findmnt /` should show `subvol=/sysroot`. `/persist` and
   `/persist/home` should be mounted. The next reboot wipes `sysroot`
   (including `/home`, except the whitelist in `impermanence.nix`).
   nix, persist, and the home subvolume stay.

8. After first login:

   ```
   fwupdmgr refresh && fwupdmgr update
   fprintd-enroll
   ```

   Use the **same** LUKS passphrase for cryptroot and cryptswap so hibernate
   resume only prompts once. Skip step 4 and GDM will not accept a login.

## Beelink

Home server. Hostname `beelink`. Forgejo at `git.infodump.org`, Beszel at
`status.infodump.org`. Caddy answers HTTP-01 and gets certificates from
Let's Encrypt production. WireGuard listens on UDP 51820 as `10.100.0.1/24`
and generates its key at `/var/lib/wireguard/wg0`. SSH is key-only for
`shrimp`. Forgejo's login user is `forgejo`.

Public registration is off. After DNS for both names points at this box
and the first boot:

```
sudo -u forgejo env FORGEJO_WORK_DIR=/var/lib/forgejo \
  forgejo admin user create --admin \
  --username shrimp --email Samir-Rashid@godsped.com
```

Beszel's agent stays stopped until the hub has issued a key and token:

```
sudo install -d -o beszel-agent -g beszel-agent /var/lib/beszel-agent
sudo install -m 640 -o root -g beszel-agent key /var/lib/beszel-agent/key
sudo install -m 640 -o root -g beszel-agent token /var/lib/beszel-agent/token
sudo systemctl start beszel-agent
```

Install from a NixOS ISO. This wipes the disk named in
`hosts/beelink/disko.nix`. Set that by-id path first. The flake input
`linkserver-deb` is a file on the laptop
(`/home/shrimp/Documents/code/firmware/LinkServer_26.9.130.x86_64.deb.bin`);
the installer evaluates the whole flake, so that path has to exist there
too (copy the file) or build `.#beelink` on the laptop and install the
closure.

1. Edit `hosts/beelink/disko.nix`. Confirm `ls -l` shows that by-id node.

2. Format and mount:

   ```
   sudo nix --extra-experimental-features "nix-command flakes" run .#disko -- \
     --mode destroy,format,mount --flake .#beelink
   ```

3. Login hash (read at activation; not in git):

   ```
   sudo mkdir -p /mnt/var/lib/secrets
   mkpasswd -m yescrypt | sudo tee /mnt/var/lib/secrets/shrimp-password
   sudo chmod 600 /mnt/var/lib/secrets/shrimp-password
   ```

4. Install: `sudo nixos-install --flake .#beelink`. Root's installer
   password is not the installed system; root is locked. `shrimp` sudoes.

5. Copy this repo to `/mnt/home/shrimp/Documents/code/nixos` and
   `chown -R 1000:1000` that home. Reboot, unlock LUKS, SSH in from the
   laptop key. Point `git.infodump.org` and `status.infodump.org` at the
   machine before expecting certificates.

`just r` on this host is `nixos-rebuild switch --flake .#beelink`.

## Layout

```
flake.nix                         inputs + framework16 and beelink
modules/nixos/                    nix, GNOME, locale, ssh (off), HM
Justfile                          just r / just build / just secret …
hosts/beelink/                    NUC: disko, ssh, forgejo, caddy, wireguard, beszel
hosts/framework16/
  default.nix                     this machine
  hardware.nix                    kernel modules only
  disko.nix                       GPT + LUKS + btrfs; enableConfig = true
  impermanence.nix                system + home whitelist, initrd rollback
  borg.nix                        borg job, off until a remote repo
  stylix.nix                      palette/fonts/cursor (catppuccin-mocha)
home/                             HM module (deployed by nixos-rebuild)
  firefox.nix                     addons from extraSpecialArgs.firefoxAddons
secrets/secrets.nix               agenix recipients (CLI only)
```

`nixosConfigurations.framework16`, `networking.hostName`, and Justfile
`uname -n` must stay identical.

## Design

**Disko owns the disk.** `enableConfig = true` generates `fileSystems`,
LUKS, and swap. `hardware.nix` is modules and CPU only. Formatting is the
disko CLI in the install section, never `nixos-rebuild`.

**Ephemeral `/` and `~/`.** `sysroot` is wiped in initrd (systemd unit
`rollback-sysroot`, not `postResumeCommands`). `/nix` stays. The `home`
subvolume is mounted at `/persist/home` and is not wiped; `~/` is a
directory on `sysroot`. `environment.persistence."/persist".users.shrimp`
bind-mounts the whitelist back onto `~/`. State that must survive is
that list, the system list in `impermanence.nix`, and
`/persist/secrets/shrimp-password`. Activate with `just rebuild-boot`
and a reboot, not `just r` — see the comment in `impermanence.nix`.

**Home Manager is a NixOS module.** One rebuild deploys OS and home.
`useGlobalPkgs` shares `pkgs` (including `allowUnfree`). Firefox add-ons
are `extraSpecialArgs.firefoxAddons` (NUR rycee), not a global overlay.

**nixos-hardware `framework-16-7040-amd`.** AMD pstate, fingerprint, fwupd,
PSR workaround, keyboard HID. Do not re-encode those.

**GNOME + GDM on Wayland.** NetworkManager only (not `networking.wireless`).
`NIXOS_OZONE_WL=1` for Electron. sshd is off.

**Neovim via `programs.neovim`.** Servers in `extraPackages`, not mason.nvim.

**Stylix** is the one palette. NixOS module only (it auto-imports into HM).

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

Grok Build (`grok` / `agent`) is nixpkgs `pkgs.grok-build`.
`GROK_DISABLE_AUTOUPDATER=1`.

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

## Soon after first boot

Not required to install. Do these when the machine is boring:

- TPM2 LUKS unlock (`systemd-cryptenroll`) with passphrase fallback
- Lanzaboote / Secure Boot (install currently needs SB off)
- Borg to a **remote**, including `/persist` (the job already lists it)
- agenix: persist an age key (sshd is off, so no host SSH key until you enable it)
- 1Password *or* lean harder into KeePassXC — Bitwarden is also installed
- Tailscale; if you want SSH later, bind sshd to `tailscale0` only
- `virt-manager` / libvirt / `podman` (VS Code has Docker/remote-containers, no runtime yet)
- `distrobox` if you need an Ubuntu escape hatch
- `uv`, `rustc`/`cargo`, `go` on PATH — editor extensions do not install toolchains
- `mpv`, OBS, Signal/Discord as you actually use them
- Framework input-module RGB / keyboard brightness via `framework-tool`
- EasyEffects + a Framework 16 speaker preset
- GSConnect if you live on a phone

## Later / dreams

- Hyprland (only when GNOME annoys you; redo screenshots, idle, portals, lid)
- Steam + gamemode + 32-bit graphics; NVIDIA bay as a **specialisation**, not stuffed into the iGPU host
- `nix-vscode-extensions` (see TODO in `home/vscode.nix`)
- nixvim/nvf when `nvim.lua` outgrows this file
- Plymouth + quiet boot
- `kanata`/`keyd` for Caps
- YubiKey/PAM u2f in addition to fprint
- Cachix/Attic if rebuilds hurt
- `ollama` + ROCm on the 780M
- Syncthing / Nextcloud
- `opensnitch`, `iwd` as NM backend (only with a symptom)
- Specialisations: `work` / `game` / `nvidia-bay`
