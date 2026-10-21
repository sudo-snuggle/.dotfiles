{ pkgs, inputs, ... }: {
  programs.firefox = {
    enable = true;

    profiles.default-release = {
      id = 0;
      name = "default-release";
      isDefault = true;

      extraConfig = builtins.readFile "${inputs.betterfox}/user.js";

      settings = {
        "dom.ipc.processCount" = 4;
        "media.eme.enabled" = true;
        # Required so Firefox loads userChrome.css & userContent.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      # Import main CSS files from your configs/browser directory
      userChrome = builtins.readFile ../configs/browser/userChrome.css;
      userContent = builtins.readFile ../configs/browser/userContent.css;
    };
  };
}