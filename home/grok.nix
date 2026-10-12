# grok-bot is the flake overlay. grok-build is nixpkgs.
# sand:// and grokbot:// are the login redirects.
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
