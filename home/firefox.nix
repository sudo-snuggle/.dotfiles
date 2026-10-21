{ pkgs, inputs, ... }: {
  programs.firefox = {
    enable = true;

    profiles.default-release = {
      id = 0;
      name = "default-release";
      isDefault = true;

      extraConfig = builtins.readFile "${inputs.betterfox}/user.js";

      # Declaratively pull extensions from rycee's NUR collection
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        sidebery
        stylus
      ];

      settings = {
        "dom.ipc.processCount" = 4;
        "media.eme.enabled" = true;

        # Stylesheet customization
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Container & Sidebar Tweak defaults
        "privacy.userContext.enabled" = true;
        "privacy.userContext.ui.enabled" = true;
        "sidebar.position_start" = true;
      };

      # Import CSS files
      userChrome = builtins.readFile ../configs/browser/userChrome.css;
      userContent = builtins.readFile ../configs/browser/userContent.css;
    };
  };
}