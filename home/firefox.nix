# Firefox via Home Manager so extensions are declarative.
# Add-ons come from extraSpecialArgs.firefoxAddons (NUR rycee, not a
# global overlay). Search-engine "extensions" in an AMO export (Amazon,
# Bing, Google, Wikipedia, …) are not add-ons; DDG is the default search.
#
# Skipped on purpose:
#   Bypass Paywalls*     — gone from AMO / legally messy
#   CORS Everywhere      — turns the browser into an open proxy
#   ActivityWatch        — needs the AW server
#   Video DownloadHelper — needs a native helper daemon
#   themes               — Dark/Light/Alpenglow/System are built-in
#   Add-ons Search Detection — built-in
{ firefoxAddons, ... }:

{
  programs.firefox = {
    enable = true;
    # First launch would otherwise disable every nix-installed add-on
    # pending a click. 0 = don't auto-disable.
    profiles.default = {
      id = 0;
      isDefault = true;
      settings = {
        "extensions.autoDisableScopes" = 0;
        "browser.startup.page" = 3; # restore previous session
        "browser.warnOnQuitShortcut" = false;
        "privacy.donottrackheader.enabled" = true;
        "signon.rememberSignons" = false; # Bitwarden / KeePassXC, not Firefox
      };
      search = {
        default = "ddg";
        force = true;
        engines = {
          "bing".metaData.hidden = true;
          "amazon".metaData.hidden = true;
          "ebay".metaData.hidden = true;
        };
      };
      userChrome = ''
        #TabsToolbar { visibility: collapse !important; }
      '';
      extensions.packages = with firefoxAddons; [
        ublock-origin
        bitwarden
        darkreader
        clearurls
        consent-o-matic
        facebook-container
        multi-account-containers
        istilldontcareaboutcookies
        leechblock-ng
        old-reddit-redirect
        privacy-possum
        single-file
        skip-redirect
        sponsorblock
        tab-session-manager
        tree-style-tab
        decentraleyes
        privacy-badger
        violentmonkey
        enhancer-for-youtube
        buster-captcha-solver
        user-agent-string-switcher
        modern-for-wikipedia
        temporary-containers
        keepassxc-browser
      ];
    };
  };
}
