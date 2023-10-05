{ config, pkgs, lib, inputs, ... }:

{
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      profiles.default = {
        id = 0;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          canvasblocker
          clearurls
          darkreader
          decentraleyes
          floccus
          i-dont-care-about-cookies
          multi-account-containers
          temporary-containers
          ublock-origin
          umatrix
        ];
        search = {
          force = true;
          default = "DuckDuckGo";
          order = [ "DuckDuckGo" "Google" ];
          engines = {
            "Google".metaData.alias = "@g";

            "GitHub" = {
              urls = [{
                template = "https://github.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.fetchurl {
                url = "https://github.githubassets.com/favicons/favicon.svg";
                sha256 = "sha256-apV3zU9/prdb3hAlr4W5ROndE4g3O1XMum6fgKwurmA=";
              }}";
              definedAliases = [ "@gh" ];
            };

            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "channel"; value = "unstable"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "NixOS Wiki" = {
              urls = [{
                template = "https://nixos.wiki/index.php";
                params = [{ name = "search"; value = "{searchTerms}"; }];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };

            "Nixpkgs Issues" = {
              urls = [{
                template = "https://github.com/NixOS/nixpkgs/issues";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@ni" ];
            };

            "Reddit" = {
              urls = [{
                template = "https://www.reddit.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              icon = "${pkgs.fetchurl {
                url = "https://www.redditstatic.com/accountmanager/favicon/favicon-512x512.png";
                sha256 = "sha256-WiXqffmuCVCOJ/rpqyhFK59bz1lKnUOp9/aoEAYRsn0=";
              }}";
              definedAliases = [ "@r" ];
            };

            "Youtube" = {
              urls = [{
                template = "https://www.youtube.com/results";
                params = [{ name = "search_query"; value = "{searchTerms}"; }];
              }];
              icon = "${pkgs.fetchurl {
                url = "www.youtube.com/s/desktop/8498231a/img/favicon_144x144.png";
                sha256 = "sha256-lQ5gbLyoWCH7cgoYcy+WlFDjHGbxwB8Xz0G7AZnr9vI=";
              }}";
              definedAliases = [ "@yt" ];
            };
          };
        };
        settings = {
          "app.shield.optoutstudies.enabled" = false;
          "browser.contentblocking.category" = "custom";
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          "browser.formfill.enable" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.enabled" = true;
          "browser.ping-centre.telemetry" = false;
          "browser.search.defaultenginename" = "DuckDuckGo";
          "browser.search.openintab" = true;
          "browser.search.region" = "DE";
          "browser.search.selectedEngine" = "DuckDuckGo";
          "browser.startup.homepage" = "about:home";
          "browser.startup.page" = 1;
          "browser.theme.content-theme" = 0;
          "browser.theme.toolbar-theme" = 0;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.uidensity" = 1;
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.topsites" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "experiments.activeExperiment" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "extensions.autoDisableScopes" = 0;
          "extensions.pocket.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "keyword.enabled" = true;
          "mousewheel.with_alt.action" = 1;
          "network.allow-experiments" = false;
          "network.cookie.lifetimePolicy" = 2;
          "places.history.enabled" = false;
          "privacy.donottrackheader.enable" = true;
          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "signon.rememberSignons" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.hybridContent.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
        };
      };
  };
}
