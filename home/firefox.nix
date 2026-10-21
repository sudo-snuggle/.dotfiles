{ pkgs, inputs, ... }: {
  programs.firefox = {
    enable = true;

    # 1. Enforce Extensions globally across profiles
    policies = {
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Sidebery
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        };
        # Stylus (Custom CSS manager for web pages)
        "{7a7a5d10-1114-4db7-a705-d8b03e35a361}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
        };
      };

    };

    # 2. Main Profile Setup
    profiles.default-release = {
      id = 0;
      name = "default-release";
      isDefault = true;

      # Betterfox user.js
      extraConfig = builtins.readFile "${inputs.betterfox}/user.js";

      settings = {
        "dom.ipc.processCount" = 4;
        "media.eme.enabled" = true;

        # Required for userChrome.css / userContent.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Container & Sidebar Tweak defaults
        "privacy.userContext.enabled" = true; # Enables Firefox Multi-Account Containers
        "privacy.userContext.ui.enabled" = true;
        "sidebar.position_start" = true; # Places sidebar on the left
      };

      # Import your core CSS stylesheets directly from your dotfiles
      userChrome = builtins.readFile ../configs/browser/userChrome.css;
      userContent = builtins.readFile ../configs/browser/userContent.css;
    };
  };
}