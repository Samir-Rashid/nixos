# Grok Bot (desktop Electron app) + Grok Build (`grok` CLI/TUI).
#
# grok-bot: flake input github:d-513/grok-bot-nix. Overlay → pkgs.grok-bot.
#   Login redirects (sand:// / grokbot://) need the .desktop file on
#   XDG_DATA_DIRS — home.packages does that; `nix run` does not.
#   In-app updater is a no-op under Nix. Pick up new pins with:
#     just update grok-bot-nix
#
# grok-build: nixpkgs (pkgs.grok-build). In-app update cannot write the
#   store path; bump it with the nixpkgs pin.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.grok-bot
    pkgs.grok-build
  ];

  # mimeapps.list is owned by Home Manager (firefox.nix). sand:// and
  # grokbot:// are the login redirects; the desktop file already claims them.
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/grokbot" = "grok-bot.desktop";
    "x-scheme-handler/sand" = "grok-bot.desktop";
  };

  # Official installer drops a self-updating copy in ~/.grok/bin. Nix owns
  # PATH now; don't let the TUI try to replace the store binary.
  home.sessionVariables.GROK_DISABLE_AUTOUPDATER = "1";
}
