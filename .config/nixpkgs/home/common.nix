# Common options that each user probably will not need to change.  A user's
# ~/.config/nixpkgs/home.nix (which imports this file), can extend and/or
# override the options set in this file.  A user should only change this file,
# committed to the main branch of the dotfiles repository, if the change should
# be merged upstream and supplied to all users of the host system.

{ config, pkgs, ... }:

with builtins;

let
  # # TODO: Is this the correct way to get this value from within home-manager? Or
  # # should it be gotten thru the given config or pkgs argument?
  # nixpkgs = import <nixpkgs/nixos> {};

  systemPath = /run/current-system/sw;
  # systemPath = nixpkgs.config.system.path;

  # This DPI corresponds to my current monitor.
  dpi = 110;
  # Defining services.xserver.dpi (in /etc/nixos/configuration.nix) confused
  # Firefox and degraded its UI, independently of its other DPI settings below.
  # dpi = nixpkgs.config.services.xserver.dpi;

  # TODO? variables for fonts, to use consistently throughout below?
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = getEnv "USER";
  home.homeDirectory = getEnv "HOME";

  #-----------------------------------------------------------------------------
  # Bash
  #-----------------------------------------------------------------------------
  programs.bash = {
    enable = true;

    sessionVariables = {
    };

    # Added as last thing in ~/.profile, after the sessionVariables part that
    # home-manager auto-generates.
    profileExtra = ''
      . $HOME/.profile-unmanaged
    '';

    # Added as first thing in ~/.bashrc, before the interactive-shell check.
    bashrcExtra = ''
    '';

    # Whatever bashrcExtra does as first thing, any following home-manager
    # options can override these same aspects of bashrcExtra if it had also done
    # these.

    # historyFileSize = 2000000;
    # historySize = historyFileSize / 4;
    # historyControl = let ignoreboth = ["ignorespace" "ignoredups"];
    #                  in ignoreboth;
    # shellOptions = [
    #   "autocd"
    #   "cdspell"
    #   "checkhash"
    #   "checkjobs"
    #   "checkwinsize"
    #   "cmdhist"
    #   "dirspell"
    #   "extglob"
    #   "globstar"
    #   "histappend"
    # ];
    # shellAliases = {
    #   l = "ls -CFhv --group-directories-first --quoting-style=c-maybe";
    #   ...
    # };

    # Added as last thing in ~/.bashrc, after the things home-manager
    # auto-generates, and after the interactive-shell check.  initExtra can
    # override/undo any preceding home-manager options.
    initExtra = ''
      source ~/.bashrc-unmanaged
    '';
  };

  #-----------------------------------------------------------------------------
  # Git
  #-----------------------------------------------------------------------------
  programs.git = rec {
    enable = true;
    userName  = config.home.username;
    userEmail = let
      rx = "[[:space:]]*([^[:space:]]+)[[:space:]]*";
      hostName = elemAt (match rx (readFile /etc/hostname)) 0;
    in
      "${userName}@${hostName}";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      credential = {
        helper = "cache --timeout ${toString (8 * 60 * 60)}";
      };
    };
  };

  #-----------------------------------------------------------------------------
  # Whether to enable GNU Info.
  #-----------------------------------------------------------------------------
  programs.info.enable = true;

  #-----------------------------------------------------------------------------
  # Whether to generate the manual page index caches using mandb(8). This allows
  # searching for a page or keyword using utilities like apropos(1).
  #
  # If you don't mind waiting a few more seconds when Home Manager builds a new
  # generation, you may safely enable this option.
  # -----------------------------------------------------------------------------
  programs.man.generateCaches = true;

  #-----------------------------------------------------------------------------
  # Firefox
  #-----------------------------------------------------------------------------
  programs.firefox = {
    enable = true;

    profiles = {

      default = {

        #-----------------------------------------------------------------------
        # The values below were discovered with the
        # ~/.mozilla/firefox/$PROFILE/user.js file and the about:config and
        # about:preferences pages.
        # -----------------------------------------------------------------------
        settings = let
          restorePreviousSession = 3;
          compact = 1;
        in {
          "browser.uidensity" = compact;

          "browser.startup.homepage" = "about:blank";
          "browser.startup.page" = restorePreviousSession;
          "browser.sessionstore.warnOnQuit" = true;
          "browser.aboutConfig.showWarning" = false;

          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.migrationExpired" = true;
          "browser.newtabpage.activity-stream.prerender" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;

          # Note: Not needed when services.xserver.dpi is set to the DPI.
          # "layout.css.devPixelsPerPx" = builtins.toString (dpi / 96.0);
          "layout.css.devPixelsPerPx" = "1.4";
          # "layout.css.dpi" = dpi;

          "font.default.x-western" = "sans-serif";
          # "font.name.sans-serif.x-western" = "Ubuntu";
          # "font.name.monospace.x-western" = "Ubuntu Mono";
          "font.size.variable.x-western" = 15;
          "font.size.monospace.x-western" = 14;
          # "font.size.fixed.x-western" = 14;
          "font.minimum-size.x-western" = 14;
          "browser.display.use_document_fonts" = 0;

          "general.smoothScroll" = false;

          "browser.search.suggest.enabled" = false;
          "browser.search.update" = false;
          "browser.search.widget.inNavBar" = true;
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.placeholderName.private" = "DuckDuckGo";
          "browser.urlbar.suggest.quicksuggest" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;

          "app.shield.optoutstudies.enabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;

          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.contentblocking.category" = "custom";

          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.addresses.usage.hasEntry" = true;
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.formautofill.firstTimeUse" = false;

          "extensions.treestyletab.autoCollapseExpandSubtreeOnAttach" = false;
          "extensions.treestyletab.autoCollapseExpandSubtreeOnSelect" = false;
          "extensions.treestyletab.insertNewChildAt" = 0;
          "extensions.treestyletab.show.context-item-reloadDescendantTabs" = true;
          "extensions.treestyletab.show.context-item-removeAllTabsButThisTree" = true;
          "extensions.treestyletab.show.context-item-removeDescendantTabs" = true;

          # Needed for Firefox to apply the userChrome.css and userContent.css
          # files (which are generated from the below).
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };

        # Needed with the Tree Style Tab extension, to hide undesired widgets.
        userChrome = ''
          #TabsToolbar {
              visibility: collapse !important;
          }

          #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
              display: none;
          }
        '';

        # Darker background for new tabs (to not blast eyes with blinding white).
        userContent = ''
          @-moz-document url("about:newtab") {
              body {
                  background-color: #888888 !important;
              }
          }

          .tab {
            font-size-adjust: 0.52 !important;
          }

          .tab:not(:hover) .closebox {
            display: none;
          }

          :root {
            --tab-height: 29px !important;
          }
          .tab {
            height: var(--tab-height) !important;
          }
        '';
      };
    };

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      tree-style-tab
      ublock-origin
    ];
  };

  #-----------------------------------------------------------------------------
  # dconf.  Affects GNOME-like desktop environments such as MATE.  The values
  # below were discovered with the CLI tool `dconf dump /`.
  # -----------------------------------------------------------------------------
  dconf.settings = {
    # TODO: Not sure this is really doing something...
    # "org/gnome/settings-daemon/plugins/power" = {
    #   idle-dim = false;
    # };

    "org/mate/marco/general" = {
      theme = "Green-Submarine";  # Or: "Green-Submarine-border"
      #TODO? button-layout = "menu:minimize,maximize,close";
      titlebar-font = "Ubuntu Medium 11";
      num-workspaces = 4;
      allow-tiling = true;
      action-double-click-titlebar = "toggle_maximize_vertically";
      show-tab-border = true;
      center-new-windows = true;
      #TODO?  compositing-manager = true;
      #TODO?  compositing-fast-alt-tab = false;
    };

    "org/mate/desktop/interface" = {
      window-scaling-factor = 1;
      #TODO? gtk-decoration-layout = "menu:minimize,maximize,close";
      font-name = "Ubuntu 13";
      document-font-name = "Ubuntu 13";
      monospace-font-name = "Ubuntu Mono 14";
      #TODO icon-theme = "Radiant-MATE";
      #TODO gtk-theme = "Menta";
      #TODO? enable-animations = true;
    };

    "org/mate/caja/desktop" = {
      font = "Ubuntu 12";
    };

    "org/mate/desktop/font-rendering" = {
      dpi = dpi * 1.0; # Converted to float.
    };

    "org/mate/desktop/peripherals/mouse" = {
      cursor-size = 24;
      cursor-theme = "redglass";
    };

    # TODO: Not needed, right?, with /etc/nixos/configuration.nix having
    #       xkbOptions = "caps:ctrl_modifier"
    # "org/mate/desktop/peripherals/keyboard/kbd" = {
    #   options = ["caps\tcaps:ctrl_modifier"];
    # };

    "org/mate/desktop/peripherals/keyboard" = {
      numlock-state = "off";
    };

    "org/mate/marco/global-keybindings" = {
      run-command-terminal = "disabled";
      show-desktop = "disabled";
      switch-to-workspace-left = "<Mod4>Left";
      switch-to-workspace-right = "<Mod4>Right";
      switch-to-workspace-up = "<Mod4>Up";
      switch-to-workspace-down = "<Mod4>Down";
      switch-to-workspace-1 = "<Mod4>1";
      switch-to-workspace-2 = "<Mod4>2";
      switch-to-workspace-4 = "<Mod4>4";
      switch-to-workspace-3 = "<Mod4>3";
    };

    "org/mate/marco/window-keybindings" = {
      toggle-shaded = "disabled";
      move-to-center = "disabled";
      move-to-side-w = "disabled";
      move-to-side-e = "disabled";
      move-to-side-n = "disabled";
      move-to-side-s = "disabled";
      move-to-corner-nw = "disabled";
      move-to-corner-ne = "disabled";
      move-to-corner-sw = "disabled";
      move-to-corner-se = "disabled";
      toggle-maximized = "<Alt><Mod4>Up";
      tile-to-side-w = "<Alt><Mod4>Left";
      tile-to-side-e = "<Alt><Mod4>Right";
      tile-to-corner-nw = "<Alt><Mod4>End";
      tile-to-corner-ne = "<Alt><Mod4>Home";
      tile-to-corner-sw = "<Alt><Mod4>Page_Down";
      tile-to-corner-se = "<Alt><Mod4>Page_Up";
      move-to-workspace-left = "<Primary><Alt><Mod4>Left";
      move-to-workspace-right = "<Primary><Alt><Mod4>Right";
      move-to-workspace-up = "<Primary><Alt><Mod4>Up";
      move-to-workspace-down = "<Primary><Alt><Mod4>Down";
    };

    "org/mate/terminal/profiles/default" = {
      foreground-color = "#000000000000";
      # visible-name = "TODO?";
      palette = "#000000000000:#828200000000:#00006E6E1010:#FCFCE9E94F4F:#100F1615C4C4:#787800008080:#000078788080:#88888A8A8585:#000000000000:#828200000000:#00006E6E1010:#FCFCE9E94F4F:#100F1615C4C4:#787800008080:#000078788080:#FFFFFFFFFFFF";
      use-system-font = false;
      silent-bell = true;
      use-theme-colors = false;
      scrollbar-position = "hidden";
      exit-action = "hold";
      default-show-menubar = false;
      font = "Ubuntu Mono 15";
      allow-bold = false;
      bold-color = "#000000000000";
      background-color = "#BDBDB8B8A0A0";
      scrollback-lines = 5000000;
    };

    "org/mate/panel/general" = {
      default-layout = "Mine";
      enable-sni-support = true;
      object-id-list = [
        "menu"
        "web-browser"
        "window-list"
        "workspace-switcher"
        "sys-load-monitor"
        "indicators"
        "clock"
      ];
      toplevel-id-list = ["bottom"];
    };

    "org/mate/panel/toplevels/bottom" = {
      expand = true;
      orientation = "bottom";
      screen = 0;
      y-bottom = 0;
      auto-hide = true;
      size = 48;
      #TODO? y = 1392;
    };

    "org/mate/panel/objects/menu" = {
      locked = true;
      toplevel-id = "bottom";
      position = 0;
      object-type = "menu";
      use-menu-path = false;
      panel-right-stick = false;
      tooltip = "Main Menu";
    };

    "org/mate/panel/objects/web-browser" = {
      locked = true;
      launcher-location = "${systemPath}/share/applications/firefox.desktop";
      position = 48;
      object-type = "launcher";
      toplevel-id = "bottom";
      panel-right-stick = false;
    };

    "org/mate/panel/objects/music-player" = {
      locked = true;
      launcher-location = "${systemPath}/share/applications/rhythmbox.desktop";
      toplevel-id = "bottom";
      position = 96;
      object-type = "launcher";
      panel-right-stick = false;
    };

    "org/mate/panel/objects/terminal" = {
      locked = true;
      launcher-location = "${systemPath}/share/applications/mate-terminal.desktop";
      toplevel-id = "bottom";
      position = 144;
      object-type = "launcher";
      panel-right-stick = false;
    };

    "org/mate/panel/objects/source-code-editor" = {
      locked = true;
      launcher-location = "${systemPath}/share/applications/emacs.desktop";
      toplevel-id = "bottom";
      position = 192;
      object-type = "launcher";
      panel-right-stick = false;
    };

    # TODO: Why isn't this showing?
    "org/mate/panel/objects/window-list" = {
      applet-iid = "WnckletFactory::WindowListApplet";
      locked = true;
      toplevel-id = "bottom";
      position = 240; # TODO: Good?
      object-type = "applet";
    };

    "org/mate/panel/objects/window-list/prefs" = {
      group-windows = "auto";
    };

    "org/mate/panel/objects/workspace-switcher" = {
      applet-iid = "WnckletFactory::WorkspaceSwitcherApplet";
      locked = true;
      toplevel-id = "bottom";
      object-type = "applet";
      panel-right-stick = false; # TODO: try true
      position = 1809; # TODO: try relative to the right side
    };

    "org/mate/panel/objects/sys-load-monitor" = {
      applet-iid = "MultiLoadAppletFactory::MultiLoadApplet";
      locked = true;
      toplevel-id = "bottom";
      object-type = "applet";
      panel-right-stick = false; # TODO: try true
      position = 2152; # TODO: try relative to the right side
    };

    "org/mate/panel/objects/sys-load-monitor/prefs" = {
      size = 70;
      speed = 2000;
      view-memload = true;
      view-netload = true;
    };

    "org/mate/panel/objects/indicators" = {
      applet-iid = "NotificationAreaAppletFactory::NotificationArea";
      locked = true;
      object-type = "applet";
      panel-right-stick = false; # TODO: try true
      position = 2368; # TODO: try relative to the right side
      toplevel-id = "bottom";
    };

    "org/mate/panel/objects/indicators/prefs" = {
      min-icon-size = 36;
    };

    "org/mate/panel/objects/clock" = {
      applet-iid = "ClockAppletFactory::ClockApplet";
      locked = true;
      toplevel-id = "bottom";
      position = 73;
      object-type = "applet";
      panel-right-stick = true;
    };

    "org/mate/panel/objects/clock/prefs" = {
      show-temperature = false;
      show-date = false;
      expand-locations = false;
      format = "12-hour";
      show-week-numbers = false;
      custom-format = "";
      show-weather = false;
    };

    # TODO?
    # "org/mate/notification-daemon" = {
    #   popup-location = "bottom_right";
    #   theme = "coco";
    # };
  };
}
