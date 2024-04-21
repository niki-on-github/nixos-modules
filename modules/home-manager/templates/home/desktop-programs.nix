{ config, pkgs, lib, ... }:
let
  firefoxSearchConfig = {
    force = true;
    default = "Google";
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

  firefoxSettings = searchEngine: {
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
    "browser.search.defaultenginename" = "${searchEngine}";
    "browser.search.openintab" = true;
    "browser.search.region" = "DE";
    "browser.search.selectedEngine" = "${searchEngine}";
    "browser.startup.homepage" = "about:home";
    "browser.startup.page" = 1;
    "browser.theme.content-theme" = 0;
    "browser.theme.toolbar-theme" = 0;
    "browser.toolbars.bookmarks.visibility" = "always";
    "browser.uidensity" = 1;
    "browser.urlbar.placeholderName" = "${searchEngine}";
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
    "browser.fixup.domainsuffixwhitelist.lan" = true;
  };

  firefoxCoreExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
    bitwarden
    decentraleyes
    floccus
    ublock-origin
    i-dont-care-about-cookies
  ];

  firefoxHardenedExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
    darkreader
    canvasblocker
    clearurls
    multi-account-containers
    temporary-containers
    umatrix
  ] ++ firefoxCoreExtensions;
in
{
  programs = {
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
    };
    git = {
      enable = true;
      lfs.enable = true;
      userName = "nix";
      userEmail = "nix@local";
      aliases = {
        aa = "add --all";
        cm = "commit -m";
        co = "checkout";
        s = "status";
      };
      extraConfig = {
        init = {
          defaultBranch = "main";        
        };
        credential = {
          helper = "cache --timeout=3600";
        };
        merge = {
          tool = "${pkgs.meld}/bin/meld";
        };
        mergetool = {
          keepBackup = false;
          prompt = false;
        };
        mergetool."meld" = {
          cmd = "${pkgs.meld}/bin/meld \"$LOCAL\" \"$MERGED\" \"$REMOTE\" --output \"$MERGED\"";
        };
        push = {
          followTags = true;
          autoSetupRemote = true;
        };
        pull = {
          rebase = false;
        };
        rerere = {
          # reuse merged conflicts, never require to merge again
          enabled = true;
        };
      };
    };
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
    };
    direnv = {
      enable = true;
      enableZshIntegration = true; # TODO: add `eval "$(direnv hook zsh)"` to your zsh config
      nix-direnv.enable = true;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
      profiles = {
        default = {
          id = 0;
          extensions = firefoxHardenedExtensions;
          search = firefoxSearchConfig;
          settings = (firefoxSettings "Google");
        };
        private = {
          id = 1;
          extensions = firefoxHardenedExtensions;
          search = firefoxSearchConfig;
          settings = (firefoxSettings "Google");
        };
        vpn = {
          id = 2;
          extensions = firefoxHardenedExtensions;
          search = firefoxSearchConfig;
          settings = (firefoxSettings "DuckDuckGo");
        };
        banking = {
          id = 3;
          extensions = firefoxCoreExtensions;
          search = firefoxSearchConfig;
          settings = (firefoxSettings "Google");
        };
        shopping = {
          id = 4;
          extensions = firefoxCoreExtensions;
          search = firefoxSearchConfig;
          settings = (firefoxSettings "Google");
        };
      };
    };
  };
}
