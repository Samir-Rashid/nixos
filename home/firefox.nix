# Add-ons come from extraSpecialArgs.firefoxAddons (NUR rycee).
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
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;

        # Firefox Home: keep top sites only.
        "browser.newtabpage.activity-stream.feeds.topsites" = true;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
        "browser.topsites.contile.enabled" = false;
        "browser.newtabpage.activity-stream.unifiedAds.tiles.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.system.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.showWeather" = false;
        "browser.newtabpage.activity-stream.newtabWallpapers.enabled" = false;
        "browser.newtabpage.activity-stream.widgets.enabled" = false;
        "browser.newtabpage.activity-stream.system.trendingSearch.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
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

  # Epiphany wins when nothing claims http/https. ~/.config is wiped on
  # boot; home-manager rewrites this file on activation. The file is
  # read-only, so other handlers (grok.nix) have to be declared too.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };

  # A regular file is already at this path (not a Home Manager symlink).
  # Activation refuses to replace it unless this is set.
  xdg.configFile."mimeapps.list".force = true;

  home.sessionVariables.BROWSER = "firefox";
}
