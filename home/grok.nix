# Grok Bot (desktop Electron app) + Grok Build (`grok` CLI/TUI).
#
# grok-bot: flake input github:d-513/grok-bot-nix. Overlay → pkgs.grok-bot.
#   Login redirects (sand:// / grokbot://) need the .desktop file on
#   XDG_DATA_DIRS — home.packages does that; `nix run` does not.
#   In-app updater is a no-op under Nix. Pick up new pins with:
#     just update grok-bot-nix
#
# grok-build: local overlay (pkgs/grok-build.nix). This nixpkgs pin still
#   has 0.2.93; bump version+hash there when you want a newer CLI.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.grok-bot
    pkgs.grok-build
  ];

  # Official installer drops a self-updating copy in ~/.grok/bin. Nix owns
  # PATH now; don't let the TUI try to replace the store binary.
  home.sessionVariables.GROK_DISABLE_AUTOUPDATER = "1";
}
