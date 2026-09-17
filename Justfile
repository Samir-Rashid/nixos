# Command wrapper for this flake. `just` prints this list with no args.
# Until the first switch, nix needs flakes enabled; we export that here.

export NIX_CONFIG := "experimental-features = nix-command flakes"

hostname := `uname -n`

# default recipe to display help information
help:
    @just --list

alias u := update
alias r := rebuild

# update one flake input (default: all, via update-all)
update INPUT:
    nix flake update {{INPUT}}

update-all:
    nix flake update

# rebuild this host. WHEN is switch | boot | test | dry-build | dry-activate | build
rebuild WHEN="switch":
    sudo nixos-rebuild {{WHEN}} --flake .#{{hostname}}

rebuild-impure WHEN="switch":
    sudo nixos-rebuild {{WHEN}} --flake .#{{hostname}} --impure

# switch this machine (uses uname -n, which must match nixosConfigurations.<name>)
rebuild-here:
    sudo nixos-rebuild switch --flake .#{{hostname}}

rebuild-boot:
    sudo nixos-rebuild boot --flake .#{{hostname}}

# build the system closure without activating. leaves ./result
build:
    nix build -L .#nixosConfigurations.{{hostname}}.config.system.build.toplevel

# eval-only sanity check
check:
    nix eval --raw .#nixosConfigurations.{{hostname}}.config.system.build.toplevel.drvPath

# QEMU VM of this config (does not touch the running system)
vm:
    nixos-rebuild build-vm --flake .#{{hostname}}

fmt:
    nix fmt

# encrypt/edit a secret listed in secrets/secrets.nix (e.g. `just secret borg-passphrase`)
secret NAME:
    cd secrets && agenix -e {{NAME}}.age

# re-encrypt all secrets after adding a key to secrets.nix
rekey:
    cd secrets && agenix --rekey

# DESTRUCTIVE. formats the disk according to hosts/framework16/disko.nix.
# nixos-rebuild never does this. you almost never want this on a running install.
disko:
    @echo "This would WIPE the Samsung NVMe. Refusing to run from just."
    @echo "If you really mean it: sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#{{hostname}}"
