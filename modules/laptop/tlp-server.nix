{ pkgs, ... }:

{
  # Disable conflicting power management daemons
  services.power-profiles-daemon.enable = false;

  # Enable thermald for Intel thermal regulation on Haswell
  services.thermald.enable = true;

  services.tlp = {
    enable = true;

    settings = {
      # --- CPU & Governor (4th Gen Intel Haswell) ---
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # --- Battery Care (Lenovo ideapad_laptop / Conservation Mode) ---
      # 0 = Standard (100%), 1 = Long_Life / Conservation Mode (~60% cap)
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 1;
      START_CHARGE_THRESH_BAT1 = 0;
      STOP_CHARGE_THRESH_BAT1 = 1;

      # --- Disk & Storage ---
      # Prevents aggressive drive-head parking (254 = no park)
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "254 254";

      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # --- Bus Power Management ---
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      USB_AUTOSUSPEND = 1;
    };
  };
}