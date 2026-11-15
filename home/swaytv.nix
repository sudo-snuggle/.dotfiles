{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.swayTv;
in
{
  options.custom.swayTv = {
    enable = lib.mkEnableOption "10-foot TV Sway configuration for Hermes";

    tvOutput = lib.mkOption {
      type = lib.types.str;
      default = "HDMI-A-1";
      description = "Display output connector connected to the TV.";
    };

    tvMode = lib.mkOption {
      type = lib.types.str;
      default = "1920x1080@60Hz";
      description = "Resolution and refresh rate for the TV output.";
    };

    internalOutput = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "LVDS-1";
      description = "Built-in laptop display to disable (set to null to leave untouched).";
    };

    launcherCommand = lib.mkOption {
      type = lib.types.str;
      default = "hermes-tv-ui";
      description = "Command executed automatically on Sway startup.";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;

      config = {
        modifier = "Mod1"; # Alt key
        terminal = "foot";

        # Disable laptop screen and output exclusively to the TV
        output =
          (lib.optionalAttrs (cfg.internalOutput != null) {
            "${cfg.internalOutput}" = {
              disable = "";
            };
          })
          // {
            "${cfg.tvOutput}" = {
              mode = cfg.tvMode;
            };
          };

        # Hide Sway status bars for a pure console/TV look
        bars = [ ];

        window = {
          border = 0;
          titlebar = false;
          commands = [
            {
              command = "fullscreen enable";
              criteria = {
                app_id = ".*";
              };
            }
            {
              command = "fullscreen enable";
              criteria = {
                class = ".*";
              };
            }
          ];
        };

        keybindings = lib.mkOptionDefault {
          "Mod1+q" = "kill";
          "Mod1+Return" = "exec foot";
        };

        startup = [
          { command = cfg.launcherCommand; }
        ];
      };
    };
  };
}